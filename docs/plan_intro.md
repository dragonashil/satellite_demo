# Intro Camera Work - 개발 계획

## 개요
- **구간**: 0:00 ~ 0:30 (약 30초)
- **목표**: 우주 원경에서 출발 → 지구 접근 → 위성으로 자연스럽게 이동 → 위성+지구가 함께 보이는 최종 구도
- **구현 방식**: GDScript + Tween 기반 카메라 애니메이션 (AnimationPlayer 대신 코드 제어로 유연성 확보)

---

## 현재 씬 좌표 정리 (setting.md 기준)

| 노드 | 위치 | 비고 |
|------|------|------|
| Earth | (0, 0, 0) | 회전 적용됨, 원점 기준 |
| Satellite_parent | (0, 0, 498.460) | MeshInstance3D, 자식으로 Satellite 보유 |
| Camera3D (현재) | (0, 69.935, 526.462) | FOV 50, 약간 아래를 향함 |
| DirectionalLight3D | (0, 198.347, 772.811) | 태양광 역할 |

---

## 카메라 경로 설계 (3단계)

### Phase 1: Deep Space → 지구 접근 (0:00 ~ 0:12, 약 12초)

```
시작점 (A): 지구로부터 매우 먼 거리
  position: (0, 200, 2500)
  look_at: Earth (0, 0, 0)
  → 지구가 작은 점처럼 보이는 우주 원경

도착점 (B): 지구 근처
  position: (0, 150, 600)
  look_at: Earth (0, 0, 0)
  → 지구가 화면 중앙에 크게 보임
```

- **이징**: `EASE_IN_OUT` (천천히 시작 → 가속 → 감속)
- **연출**: 별 배경 속에서 지구가 점점 커지는 느낌
- **선택사항**: 접근하면서 카메라 약간 회전 (단조로움 방지)

### Phase 2: 지구 포커스 → 위성 방향 패닝 (0:12 ~ 0:22, 약 10초)

```
시작점 (B): Phase 1 도착점
  position: (0, 150, 600)
  look_at: Earth (0, 0, 0)

도착점 (C): 위성과 지구 사이 중간 지점
  position: (80, 100, 480)
  look_at: Satellite_parent (0, 0, 498.460)
  → 카메라가 옆으로 이동하면서 시선이 지구 → 위성으로 자연스럽게 전환
```

- **이징**: `EASE_IN_OUT`
- **연출**: look_at 대상을 Earth → Satellite_parent로 보간 (Quaternion slerp)
- **핵심**: position 이동과 look_at 전환을 동시에 수행하여 자연스러운 패닝

### Phase 3: 위성 최종 구도 정착 (0:22 ~ 0:30, 약 8초)

```
시작점 (C): Phase 2 도착점
  position: (80, 100, 480)

도착점 (D): 최종 카메라 위치 (위성 비스듬히 + 지구 배경)
  position: (-120, 60, 540)
  look_at: Satellite_parent (0, 0, 498.460)에서 약간 아래 (0, -20, 498)
  → 위성이 화면 우측, 지구가 좌측 배경에 걸치는 구도
```

- **이징**: `EASE_OUT` (부드럽게 감속하며 정착)
- **연출**: 최종 구도에서 위성이 주 피사체, 지구가 배경으로 함께 보임
- **FOV**: 50 유지 (setting.md 기준)

---

## 구도 다이어그램 (Top-down View)

```
            Earth (0,0,0)
               ●


                        Satellite (0, 0, 498)
                             ▲

  (D) 최종 카메라                    (C) 중간
   (-120, 60, 540)                (80, 100, 480)
        ◆ ----→ look_at ----→ ▲

                                         ↑
                                    (B) (0, 150, 600)
                                         ↑
                                         ↑
                                    (A) (0, 200, 2500)
                                      [시작점]
```

---

## 구현 파일 구조

### 1. `scripts/intro_camera.gd` (Camera3D에 attach)

```
주요 로직:
- _ready()에서 인트로 시퀀스 시작
- 각 Phase를 순차적 Tween 체인으로 구성
- Phase 간 자연스러운 연결을 위해 Tween.chain() 활용
```

**핵심 함수:**

| 함수 | 역할 |
|------|------|
| `start_intro()` | 인트로 시퀀스 전체 시작 |
| `_phase1_approach_earth(duration)` | Deep space → 지구 접근 |
| `_phase2_pan_to_satellite(duration)` | 지구 → 위성 방향 패닝 |
| `_phase3_final_framing(duration)` | 최종 구도 정착 |
| `_interpolate_look_at(from, to, weight)` | look_at 대상 부드럽게 전환 |

**Tween 사용 패턴:**
```gdscript
# 위치 이동
tween.tween_property(camera, "global_position", target_pos, duration)
    .set_ease(Tween.EASE_IN_OUT)
    .set_trans(Tween.TRANS_CUBIC)

# look_at 보간은 _process()에서 weight 값으로 slerp 처리
# Tween으로 weight(0→1)를 변화시키고, _process()에서 실제 회전 적용
```

### 2. `main.tscn` 수정 사항

- Camera3D 노드에 `intro_camera.gd` 스크립트 연결
- Camera3D 초기 위치를 Phase 1 시작점 (A)로 변경:
  - position: (0, 200, 2500)
- 인트로 완료 후 현재 설정된 위치로 돌아올 필요 없음 (Phase 3 최종 위치가 새로운 기본 위치)

---

## 추가 연출 (선택사항)

| 항목 | 설명 | 우선순위 |
|------|------|----------|
| 타이틀 텍스트 | Phase 1 중 "Satellite Orbit Simulation" 페이드인 | 중 |
| 지구 자전 | Earth 노드 느린 Y축 회전 | 높 |
| 위성 패널 펼침 | Phase 3 도착 시 위성 태양전지판 전개 애니메이션 | 낮 |
| 화면 페이드인 | 0:00에 검은 화면에서 서서히 밝아짐 | 중 |
| 인트로 스킵 | 아무 키 입력 시 Phase 3 최종 위치로 즉시 이동 | 높 |

---

## 개발 순서

1. **`scripts/intro_camera.gd` 작성** — Tween 기반 3단계 카메라 이동
2. **look_at 보간 구현** — Quaternion slerp로 시선 전환
3. **main.tscn에 스크립트 연결** — Camera3D 초기 위치 설정
4. **타이밍 튜닝** — 에디터에서 실행하며 duration, 이징, 좌표 미세조정
5. **추가 연출 적용** — 인트로 스킵, 타이틀 텍스트 등

---

## 주의사항

- 좌표값은 현재 씬 스케일 기준 추정치이므로, **실제 테스트 후 미세조정 필수**
- Satellite_parent 위치 (0, 0, 498.460)가 지구에서 매우 멀므로 카메라 이동 거리가 큼 → 이징 커브가 중요
- look_at 전환 시 gimbal lock 방지를 위해 Quaternion.slerp() 사용
- Tween은 `create_tween()`으로 생성 (Godot 4.x 방식)
