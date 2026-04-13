# Satellite Orbit Demo - Product Requirements Document

## 1. Overview

Satellite Orbit Demo는 Godot 4.6으로 개발된 인터랙티브 3D 위성 궤도 시뮬레이션 데모이다.
위성의 궤도 진입, 태양 전지판 전개, 궤도 운행, 다양한 궤도 유형 비교까지의 과정을
5단계 시퀀스로 시각화하여 교육 목적으로 활용할 수 있다.

- **엔진**: Godot 4.6
- **렌더링**: Forward Plus / DirectX 12 (Windows)
- **물리 엔진**: Jolt Physics
- **해상도**: 1920 x 1080
- **메인 씬**: `res://main.tscn`

---

## 2. Scene Structure

```
Main (Node3D)
├─ DemoController (Node)               # 전체 흐름 관리
├─ WorldEnvironment                     # HDR 우주 배경 (PanoramaSky)
├─ DirectionalLight3D                   # 태양광 (그림자 활성화)
├─ Earth (Node3D)                       # 지구 3D 모델 (GLB)
├─ Satellite_parent (MeshInstance3D)    # 위성 컨테이너
│  └─ Satellite (FBX)                  # 위성 3D 모델 + AnimationPlayer
├─ Camera3D                             # 메인 카메라 (intro_camera.gd)
└─ UILayer (CanvasLayer, layer=10)      # 모든 UI 요소
   ├─ SatelliteCallout                  # 위성 말풍선 UI
   ├─ SpacePrompt                       # "Press SPACE to continue"
   ├─ CamViewLabel                      # 현재 카메라 뷰 이름
   ├─ EscHintLabel                      # 키보드 조작 힌트
   ├─ OrbitNavLabel                     # 궤도 전환 네비게이션
   ├─ CamSettingsPanel                  # 카메라 위치 슬라이더 패널
   ├─ StartScreen                       # 시작 화면
   └─ PauseMenu                         # 일시정지 메뉴
```

---

## 3. Scripts

| 파일 | 클래스/상속 | 역할 |
|------|-------------|------|
| `demo_controller.gd` | Node | 전체 데모 흐름 상태 머신, 입력 처리, Phase 전환 |
| `intro_camera.gd` | Camera3D | Phase 1 인트로 카메라 애니메이션 |
| `camera_rig.gd` | Node (CameraRig) | 5종 카메라 뷰 전환 시스템 |
| `camera_settings_panel.gd` | PanelContainer | 카메라 위치 실시간 슬라이더 조정 |
| `orbit_data.gd` | (OrbitData) | 4종 궤도 파라미터 정적 데이터 |
| `orbit_mover.gd` | Node (OrbitMover) | 위성 궤도 운동 (케플러 법칙 적용) |
| `orbit_path.gd` | MeshInstance3D (OrbitPath) | 궤도 경로 3D 선 렌더링 |
| `satellite_callout.gd` | Control | 위성 연결 말풍선 UI |
| `start_screen.gd` | Control | 시작 화면 (타이틀 + START 버튼) |
| `pause_menu.gd` | Control | ESC 일시정지 메뉴 |
| `measure_earth.gd` | Node3D | (디버그) 지구 크기 측정 유틸리티 |

---

## 4. Demo Phases

### State Machine

```
INTRO → WAIT_PHASE2 → PHASE2_PLAYING → WAIT_PHASE3 → PHASE3_PLAYING
→ WAIT_PHASE4 → PHASE4_PLAYING → WAIT_PHASE5 → PHASE5_PLAYING → DONE
```

각 `WAIT_*` 상태에서 SPACE를 누르면 다음 Phase로 진행한다.

---

### Phase 0: Start Screen

| 항목 | 내용 |
|------|------|
| 상태 | 시작 전 (INTRO) |
| 화면 | 반투명 어두운 배경 위에 타이틀, 설명, START 버튼 |
| START 버튼 | 0.8초 주기로 깜빡임 (alpha 1.0 ↔ 0.3) |
| 동작 | START 클릭 → 0.5초 페이드아웃 → `start_pressed` 시그널 → Phase 1 시작 |
| 설명 텍스트 | 위성 궤도 역학 시뮬레이션 소개, GEO/LEO/MEO/Molniya 궤도 유형 안내 |

---

### Phase 1: Intro Camera (Satellite Orbit Insertion)

| 항목 | 내용 |
|------|------|
| 상태 | `INTRO` |
| 지속 시간 | 8초 |
| 카메라 | 위성 기준 오프셋 (40, 30, 150) → (8, 3, 10)으로 접근 |
| 시선 | 항상 위성 중심을 바라봄 |
| 이징 | EASE_IN_OUT, TRANS_SINE |
| 말풍선 | 인트로 완료 후 "1. Satellite Orbit Insertion" 페이드인 |
| 스킵 | 아무 키 또는 마우스 클릭으로 즉시 최종 위치로 이동 |
| 종료 | `intro_finished` 시그널 발신 → WAIT_PHASE2 |

---

### Phase 2: Solar Panel Deployment

| 항목 | 내용 |
|------|------|
| 상태 | `PHASE2_PLAYING` |
| 카메라 | 위성 위치 + (15, 8, 25)로 줌아웃 (3초 Tween) |
| 애니메이션 | AnimationPlayer "Take 001" 재생 (태양 전지판 전개) |
| 말풍선 | "2. Solar Panel Deployment" |
| 종료 | 애니메이션 완료 → WAIT_PHASE3 |

---

### Phase 3: Satellite Position Adjustment

| 항목 | 내용 |
|------|------|
| 상태 | `PHASE3_PLAYING` |
| 지속 시간 | 5초 |
| 동작 | 위성 Y축 -136도 회전 (위치 보정) |
| 카메라 | 위성 추적 모드 (Phase 2 종료 시 오프셋 유지) |
| 말풍선 | "3. Satellite Position Adjustment" |
| 이징 | EASE_IN_OUT, TRANS_SINE |
| 종료 | 회전 완료 → WAIT_PHASE4 |

---

### Phase 4: GEO Orbit Operation

| 항목 | 내용 |
|------|------|
| 상태 | `PHASE4_PLAYING` |
| 지속 시간 | 10초 |
| 궤도 | GEO (정지궤도, 반지름 950, 주기 30초) |
| 위성 이동 | 궤도 위치로 즉시 워프 (보간 없음) |
| 궤도선 | 시안 색상 3D 선 렌더링, 1초 페이드인 |
| 지구 회전 | 0.1 rad/s로 Y축 회전 시작 |
| 카메라 | CameraRig 활성화, OVERVIEW 뷰 (0, 600, 1800) |
| UI 활성화 | CamViewLabel, EscHintLabel 표시, C키 카메라 설정 활성화 |
| 말풍선 | "Geostationary Orbit (GEO)" + 궤도 정보 |
| 종료 | 10초 타이머 → WAIT_PHASE5 |

---

### Phase 5: Orbit Comparison

| 항목 | 내용 |
|------|------|
| 상태 | `PHASE5_PLAYING` |
| 지속 시간 | 무제한 (사용자 조작) |
| 조작 | ← → 방향키로 4종 궤도 순환 전환 |
| 전환 순서 | GEO → LEO → MEO → Molniya (wrapping) |
| 전환 과정 | 기존 궤도 페이드아웃(0.5s) → 새 궤도 페이드인(0.5s) → 위성 이동(1s Tween) → 공전 시작 |
| UI | OrbitNavLabel에 "< 궤도이름 >" 표시 |
| 말풍선 | 선택된 궤도의 title + description |

---

## 5. Camera System

### 5.1 Intro Camera (`intro_camera.gd`)

- Phase 1 전용 카메라 연출
- 위성 기준 상대 오프셋으로 이동
- `skip_intro` export 변수로 인트로 건너뛰기 가능

### 5.2 Camera Rig (`camera_rig.gd`)

Phase 4 이후 숫자키 1~5로 전환. 전환 시 0.8초 Tween 애니메이션.

| 뷰 | 키 | 위치 | 시선 대상 | 유형 |
|----|----|------|-----------|------|
| Satellite Close-up | 1 | 위성 뒤쪽 (지구 반대편), 거리 80, 높이 20 | 위성 | 추적 |
| Orbit Side View | 2 | (1400, 100, 0) | 지구 중심 | 고정 |
| Earth Overview | 3 | (0, 600, 1800) | 지구 중심 | 고정 |
| Top-down View | 4 | (0, 1600, 1) | 지구 중심 | 고정 |
| Tracking View | 5 | 위성 + (0, 20, 60) | 위성 | 추적 |

#### Close-up 카메라 위치 계산

```gdscript
func _calc_closeup_position() -> Vector3:
    var sat_pos := _satellite.global_position
    var radial_dir := sat_pos.normalized()
    return sat_pos + radial_dir * closeup_distance + Vector3.UP * closeup_height
```

지구 중심 → 위성 방향의 연장선상에 카메라를 배치하여 배경에 지구가 보이도록 한다.

### 5.3 Camera Settings Panel (`camera_settings_panel.gd`)

- C키로 토글 (Phase 4 이후)
- 화면 우측 배치
- X/Y/Z 슬라이더 (범위: -3000 ~ 3000)
- 뷰별 조정 대상:

| 뷰 | X 슬라이더 | Y 슬라이더 | Z 슬라이더 |
|----|-----------|-----------|-----------|
| CLOSEUP | closeup_distance | closeup_height | (미사용) |
| TRACKING | offset.x | offset.y | offset.z |
| 고정 뷰 | position.x | position.y | position.z |

---

## 6. Orbit System

### 6.1 Orbit Data (`orbit_data.gd`)

지구 반지름 = 400 Godot 단위 기준 시각적 압축 스케일 적용.

| 궤도 | 반지름 | 장반경 | 이심률 | 경사각 | 주기(데모) | 색상 | 실제 고도 |
|------|--------|--------|--------|--------|-----------|------|----------|
| GEO | 950 | 950 | 0.0 | 0.0° | 30초 | 시안 | 35,786 km |
| LEO | 480 | 480 | 0.0 | 51.6° | 8초 | 초록 | 400 km |
| MEO | 700 | 700 | 0.0 | 55.0° | 16초 | 노랑 | 20,200 km |
| Molniya | - | 790 | 0.392 | 63.4° | 20초 | 주황적 | 600~39,700 km |

### 6.2 Orbit Motion (`orbit_mover.gd`)

- **원형 궤도**: `r = radius` (일정 반지름)
- **타원 궤도**: `r = a(1 - e²) / (1 + e·cos(θ))` (극좌표 형식)
- **각속도**: `ω = 2π / period`
- **케플러 제2법칙**: 이심률 > 0.01일 때 반지름에 따라 각속도 보정
  - `ω_adjusted = ω × (r_avg² / r²)`
  - 근지점에서 빠르게, 원지점에서 느리게
- **경사각**: X축 회전 행렬로 적용
- **위성 방향**: 항상 지구 중심 (0,0,0)을 바라봄

### 6.3 Orbit Path Rendering (`orbit_path.gd`)

- ImmediateMesh + PRIMITIVE_LINE_STRIP
- 128개 세그먼트
- StandardMaterial3D: 언셰이드, 알파 투명
- 깊이 테스트 활성화 (지구 뒤로 가면 가려짐)
- 페이드인/아웃 애니메이션 지원

---

## 7. UI System

### 7.1 Start Screen (`start_screen.gd`)

| 요소 | 내용 |
|------|------|
| 배경 | ColorRect, 85% 불투명 어두운 색 (0.02, 0.02, 0.05) |
| 타이틀 | "Satellite Orbit Demo" (48pt) |
| 설명 | 시뮬레이션 소개 5줄 (20pt) |
| 버튼 | "START" (36pt), 0.8초 깜빡임, 스타일박스 적용 |
| 동작 | 클릭 → 페이드아웃(0.5s) → `start_pressed` 시그널 → `queue_free()` |
| 프로세스 | PROCESS_MODE_ALWAYS |

### 7.2 Pause Menu (`pause_menu.gd`)

| 요소 | 내용 |
|------|------|
| 배경 | ColorRect, 50% 불투명 검정 |
| 패널 | 중앙 배치, 어두운 배경 (0.05, 0.05, 0.1, 92%) |
| 타이틀 | "PAUSED" (32pt) |
| Resume | 메뉴 닫기 + 게임 재개 |
| Restart | `get_tree().reload_current_scene()` |
| Exit | `get_tree().quit()` |
| 토글 | ESC키 (게임 시작 후에만 동작) |
| 일시정지 | `get_tree().paused = true/false` |
| 프로세스 | PROCESS_MODE_ALWAYS |

### 7.3 Satellite Callout (`satellite_callout.gd`)

- 위성 화면 좌표 + 오프셋 (120, -100)에 패널 배치
- 위성 ↔ 패널 사이 흰색 선 (2px) 연결
- 매 프레임 3D→2D 프로젝션으로 위치 갱신
- 인트로 완료 시 0.8초 페이드인

### 7.4 HUD Labels

| 라벨 | 위치 | 표시 시점 | 내용 |
|------|------|----------|------|
| CamViewLabel | 좌상단 (20, 20) | Phase 4~ | 현재 카메라 뷰 이름 |
| EscHintLabel | 좌상단 (20, 58) | Phase 4~ | 키보드 조작 힌트 4줄 |
| SpacePrompt | 하단 중앙 | WAIT 상태 | "Press SPACE to continue" (깜빡임) |
| OrbitNavLabel | 하단 중앙 | Phase 5 | "< 궤도이름 >" |

#### EscHintLabel 내용

```
1~5: Camera View
ESC: Menu
C: Camera Option
Arrow Left/Right: Change Orbit
```

### 7.5 UI 스타일

모든 패널과 버튼은 일관된 스타일박스를 사용한다.

| 스타일 | 배경색 | 테두리 | 모서리 |
|--------|--------|--------|--------|
| Callout 패널 | (0.1, 0.1, 0.15, 85%) | 흰색 1px 80% | 6px |
| Settings 패널 | (0.05, 0.05, 0.1, 90%) | 회색 1px 80% | 8px |
| Pause 패널 | (0.05, 0.05, 0.1, 92%) | 회색 1px 80% | 8px |
| 버튼 Normal | (0.15, 0.15, 0.2, 90%) | 밝은 회색 1px 80% | 6px |
| 버튼 Hover | (0.25, 0.25, 0.35, 95%) | 흰색 1px 90% | 6px |
| 버튼 Pressed | (0.1, 0.1, 0.15, 95%) | 회색 1px 80% | 6px |

---

## 8. Input Controls

### 8.1 전체 입력 맵

| 키 | 동작 | 활성 구간 |
|----|------|----------|
| START 버튼 클릭 | 데모 시작 | 시작 화면 |
| 아무 키 / 마우스 | 인트로 스킵 | Phase 1 |
| SPACE | 다음 단계 진행 | WAIT 상태 |
| 1~5 | 카메라 뷰 전환 | Phase 4~ |
| C | 카메라 설정 패널 토글 | Phase 4~ |
| ← → | 궤도 전환 | Phase 5 |
| ESC | 일시정지 메뉴 토글 | 게임 시작 후 항상 |

### 8.2 입력 우선순위 (`_unhandled_input`)

1. ESC (일시정지 메뉴) — 일시정지 중에도 동작
2. 일시정지 중이면 나머지 입력 차단
3. C (카메라 설정 토글) — Phase 4 이후
4. 1~5 (카메라 뷰 전환) — CameraRig 활성 시
5. SPACE (단계 진행) — WAIT 상태
6. ← → (궤도 전환) — Phase 5

---

## 9. Coordinate System

| 오브젝트 | 초기 위치 |
|---------|----------|
| 지구 (Earth) | (0, 0, 0) — 원점 |
| 위성 (Satellite_parent) | (0, 28.057, 498.46) |
| 지구 반지름 (시각적) | 400 Godot 단위 |

- Y축 = 위 (Godot 표준)
- 모든 궤도는 원점 중심
- 경사각은 X축 회전으로 적용

---

## 10. Signal Flow

```
StartScreen.start_pressed
  → DemoController._on_start_pressed()
    → IntroCamera.start_intro()

IntroCamera.intro_finished
  → DemoController._on_intro_finished()
  → SatelliteCallout._show()

AnimationPlayer.animation_finished
  → DemoController._on_phase2_done()

CameraRig.view_changed
  → DemoController._on_view_changed()
```

---

## 11. Process Mode

| 노드 | Process Mode | 이유 |
|------|-------------|------|
| DemoController | ALWAYS | 일시정지 중 ESC 입력 처리 |
| StartScreen | ALWAYS | 시작 전 UI 동작 |
| PauseMenu | ALWAYS | 일시정지 중 메뉴 조작 |
| CamSettingsPanel | ALWAYS | C키 토글 응답 |
| 나머지 노드 | INHERIT | 일시정지 시 멈춤 |

---

## 12. Assets

| 경로 | 유형 | 설명 |
|------|------|------|
| `assets/HDR_multi_nebulae_3.hdr` | HDR 텍스처 | 우주 배경 (PanoramaSky) |
| `assets/3d/earth/Earth_1_12756.glb` | 3D 모델 | 지구 (GLB 포맷) |
| `assets/3d/satellite/satellite_re.fbx` | 3D 모델 | 위성 + 애니메이션 (FBX 포맷) |
