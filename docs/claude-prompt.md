# Claude AI 프롬프트 채팅 기능 - 구현 검토서

## 1. 개요

Satellite Orbit Demo에 Claude AI 채팅 인터페이스를 추가하여, 사용자가 위성/우주/로켓 등에 대해 자연어로 질문하고 답변을 받을 수 있도록 한다.

---

## 2. 기술 가능성 검토

### 2.1 Godot에서 API 호출

Godot 4.6은 `HTTPRequest` 노드를 기본 제공하며, Anthropic Claude API(REST)에 HTTPS 요청을 보낼 수 있다.

| 항목 | 지원 여부 | 비고 |
|------|-----------|------|
| HTTPS 요청 | O | HTTPRequest 노드 기본 지원 |
| JSON 파싱 | O | `JSON.parse_string()` 내장 |
| POST 요청 | O | `request()` 메서드로 body 전달 가능 |
| 커스텀 헤더 | O | `x-api-key`, `content-type` 등 설정 가능 |
| 비동기 처리 | O | `request_completed` 시그널 기반 (UI 블로킹 없음) |

**결론: 기술적으로 구현 가능하다.**

### 2.2 필요 조건

- **Anthropic API Key**: 사용자가 자신의 API 키를 입력하거나, 환경변수/설정 파일로 제공해야 한다.
- **인터넷 연결**: 실시간 API 호출이 필요하므로 오프라인 환경에서는 사용 불가.
- **API 비용**: Claude API는 토큰 단위 과금. 교육용 데모의 짧은 질의응답은 비용이 매우 낮다.

---

## 3. 아키텍처

### 3.1 신규 파일

| 파일 | 유형 | 역할 |
|------|------|------|
| `scripts/claude_chat.gd` | GDScript | API 호출 및 응답 처리 로직 |
| `scripts/claude_chat_panel.gd` | GDScript | 채팅 UI 패널 제어 |

### 3.2 씬 구조 변경

```
UILayer (CanvasLayer, layer=10)
├─ ... (기존 UI 요소)
└─ ClaudeChatPanel (PanelContainer)         # 신규
   ├─ VBoxContainer
   │  ├─ TitleBar (HBoxContainer)
   │  │  ├─ TitleLabel ("AI Assistant")
   │  │  └─ CloseButton ("X")
   │  ├─ ChatScroll (ScrollContainer)
   │  │  └─ ChatLog (RichTextLabel)        # 대화 내역 표시
   │  └─ InputBar (HBoxContainer)
   │     ├─ InputField (LineEdit)           # 질문 입력
   │     └─ SendButton ("Send")            # 전송 버튼
   └─ HTTPRequest                           # API 호출 노드
```

### 3.3 입력 키 할당

| 키 | 동작 | 비고 |
|----|------|------|
| **Q** | 채팅 패널 토글 | Phase 4 이후 활성화 (기존 키와 충돌 없음) |
| **Enter** | 메시지 전송 | 입력 필드 포커스 상태에서만 동작 |
| **ESC** | 채팅 패널 닫기 | 기존 일시정지 메뉴보다 우선 처리 |

EscHintLabel에 `Q: AI Chat` 항목을 추가한다.

---

## 4. API 통신 설계

### 4.1 요청 형식

```
POST https://api.anthropic.com/v1/messages
```

**헤더:**
```
x-api-key: {API_KEY}
anthropic-version: 2023-06-01
content-type: application/json
```

**요청 본문:**
```json
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "system": "당신은 위성, 우주, 로켓에 대한 교육용 AI 어시스턴트입니다. ...",
  "messages": [
    {"role": "user", "content": "정지궤도 위성은 왜 적도 상공에 있나요?"}
  ]
}
```

### 4.2 시스템 프롬프트 (안)

```
You are an educational AI assistant embedded in a satellite orbit simulation demo.
You answer questions about satellites, orbital mechanics, space, rockets, and launch vehicles accurately and in a friendly manner.

Orbit types covered in this demo:
- GEO (Geostationary Orbit): Altitude 35,786 km, Period 24 hours, Eccentricity 0, Inclination 0°
- LEO (Low Earth Orbit): Altitude 400 km, Period ~90 min, Inclination 51.6°
- MEO (Medium Earth Orbit): Altitude 20,200 km, Period ~12 hours, Inclination 55°
- Molniya Orbit: Altitude 600–39,700 km, Eccentricity 0.74, Inclination 63.4°

Rules:
- Always respond in English.
- Keep answers concise, within 3–5 sentences.
- Relate your explanations to the orbits shown in the demo when relevant.
- If a question is unrelated to space, satellites, or rockets, politely guide the user back to the topic.
```

### 4.3 GDScript 핵심 코드 (개요)

```gdscript
# claude_chat.gd
extends Node

const API_URL := "https://api.anthropic.com/v1/messages"
var api_key := ""
var conversation: Array[Dictionary] = []

func send_message(user_text: String) -> void:
    conversation.append({"role": "user", "content": user_text})
    
    var body := {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "system": SYSTEM_PROMPT,
        "messages": conversation
    }
    
    var headers := [
        "x-api-key: %s" % api_key,
        "anthropic-version: 2023-06-01",
        "content-type: application/json"
    ]
    
    $HTTPRequest.request(API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_request_completed(result, code, headers, body):
    var json = JSON.parse_string(body.get_string_from_utf8())
    var reply = json["content"][0]["text"]
    conversation.append({"role": "assistant", "content": reply})
    emit_signal("response_received", reply)
```

### 4.4 대화 흐름

```
사용자 질문 입력 → SendButton 클릭 또는 Enter
→ 입력 필드 비활성화 + "Thinking..." 표시
→ HTTPRequest POST 전송
→ request_completed 시그널 수신
→ 응답 텍스트 ChatLog에 추가
→ 입력 필드 재활성화
```

---

## 5. API 키 관리

보안을 위해 API 키를 코드에 하드코딩하지 않는다.

### 방법 1: 환경변수 (권장)

```gdscript
var api_key := OS.get_environment("ANTHROPIC_API_KEY")
```

### 방법 2: 최초 실행 시 입력 다이얼로그

채팅 패널을 처음 열 때 API 키 입력 창을 표시하고, 세션 동안 메모리에 보관한다. 디스크에 저장하지 않는다.

### 방법 3: 설정 파일

`user://claude_config.json`에 저장. 단, `.gitignore`에 추가하고 빌드 배포 시 제외해야 한다.

**권장: 방법 1(환경변수) + 방법 2(폴백 입력창)** 조합

---

## 6. UI 스타일

기존 프로젝트의 다크 SF 테마에 맞춘다.

| 요소 | 스타일 |
|------|--------|
| 패널 배경 | `Color(0.05, 0.05, 0.1, 0.92)` |
| 패널 테두리 | 회색 1px, alpha 0.8, radius 8px |
| 타이틀 | 16pt, 흰색, bold |
| 채팅 로그 | 14pt, RichTextLabel (BBCode 활성화) |
| 사용자 메시지 | `[color=cyan]> You: question text[/color]` |
| AI 응답 | `AI: response text` (흰색 기본 텍스트) |
| 입력 필드 | 어두운 배경, 흰색 텍스트, placeholder "Ask about satellites, orbits, rockets...", 포커스 시 시안 테두리 |
| 전송 버튼 | "Send" 텍스트, 기존 버튼 스타일박스 재사용 |

### 패널 크기 및 위치

- **크기**: 450 x 500px (화면 좌측 하단)
- **위치**: 화면 왼쪽 아래, 기존 UI 요소와 겹치지 않도록 배치
- **애니메이션**: 0.3초 슬라이드업 등장, 슬라이드다운 퇴장

---

## 7. 고려사항 및 제약

### 7.1 주의사항

| 항목 | 내용 |
|------|------|
| API 키 노출 | 빌드 배포 시 키를 포함하면 안 됨. 환경변수 또는 사용자 입력 방식 사용 |
| 네트워크 오류 | 타임아웃/실패 시 사용자에게 에러 메시지 표시 필요 |
| 응답 지연 | 2~5초 소요 가능. "Thinking..." 인디케이터 필수 |
| 토큰 비용 | max_tokens를 1024로 제한하여 비용 관리 |
| 입력 충돌 | 텍스트 입력 중 게임 키 입력이 동작하지 않도록 포커스 관리 필요 |
| 일시정지 | 채팅 패널은 `PROCESS_MODE_ALWAYS`로 설정하여 일시정지 중에도 사용 가능 |

### 7.2 입력 포커스 처리

채팅 입력 필드에 포커스가 있을 때 `demo_controller.gd`의 `_unhandled_input`이 키 입력을 가로채지 않도록 처리해야 한다.

```gdscript
# demo_controller.gd 수정
func _unhandled_input(event: InputEvent) -> void:
    # 채팅 입력 중이면 게임 입력 무시
    if _chat_panel and _chat_panel.is_input_focused():
        return
    # ... 기존 입력 처리
```

LineEdit가 포커스를 가지면 자동으로 키 입력을 소비하므로, `_unhandled_input`에서는 이미 처리되지 않은 이벤트만 수신된다. 그러나 안전을 위해 명시적 체크를 권장한다.

---

## 8. 구현 단계

### Step 1: 채팅 UI 구성
- `ClaudeChatPanel` 씬 노드 구성 (main.tscn의 UILayer 하위)
- 스타일박스 적용
- Q키 토글 연결

### Step 2: API 통신 모듈
- `claude_chat.gd` 작성
- HTTPRequest 노드 연결
- API 키 입력/환경변수 로딩

### Step 3: 대화 흐름 연결
- 사용자 입력 → API 호출 → 응답 표시
- 에러 처리 (네트워크 오류, 인증 실패, 타임아웃) — 에러 메시지도 영어로 표시
- 대화 기록 유지 (세션 내)

### Step 4: 통합 및 테스트
- `demo_controller.gd`에 Q키 입력 추가
- 입력 포커스 충돌 테스트
- EscHintLabel에 `Q: AI Chat` 추가
- 일시정지 중 채팅 동작 확인

---

## 9. 결론

| 평가 항목 | 결과 |
|-----------|------|
| 기술적 구현 가능성 | **가능** (Godot HTTPRequest + Claude API) |
| 난이도 | **중** (API 통신 + UI 구성 + 포커스 관리) |
| 기존 코드 영향 | **낮음** (UILayer에 노드 추가 + demo_controller에 키 입력 1개 추가) |
| 필수 외부 의존 | Anthropic API Key, 인터넷 연결 |

**Godot 4.6의 HTTPRequest 노드를 활용하여 Claude API와 통신하는 채팅 인터페이스를 구현할 수 있다.** 기존 프로젝트 구조와 UI 테마를 유지하면서 최소한의 수정으로 통합 가능하다.
