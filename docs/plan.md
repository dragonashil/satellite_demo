# Satellite Orbit Simulation Demo - Development Plan

## Project Overview
- **Engine**: Godot 4.6 (Forward Plus, D3D12)
- **Duration**: 5분 인터랙티브 데모
- **목적**: 위성이 궤도 진입 → 패널 전개 → 위치 보정 → 궤도 운행까지의 과정을 교육용으로 시연
- **조작**: SPACE 키로 단계 진행

---

## Current Scene Tree

```
Main (Node3D)
├── DemoController (Node)           # demo_controller.gd - 전체 흐름 상태 관리
├── WorldEnvironment                # HDR 우주 배경
├── DirectionalLight3D              # 태양광
├── Earth (GLB)                     # 지구 모델 (원점)
├── Satellite_parent (MeshInstance3D) # 위성 부모 (0, 28, 498)
│   └── Satellite (FBX)             # 위성 모델 + AnimationPlayer
├── Camera3D                        # intro_camera.gd
└── UILayer (CanvasLayer)
	├── SatelliteCallout (Control)   # satellite_callout.gd - 말풍선 + 연결선
	│   └── Panel > Label
	└── SpacePrompt (Label)          # "Press SPACE to continue" 깜빡임
```

---

## Demo Flow (5 Phases)

| Phase | 이름 | 설명 | 상태 |
|-------|------|------|------|
| 1 | Satellite Orbit Insertion | 카메라 접근 → 위성 클로즈업 + 말풍선 | ✅ 완료 |
| 2 | Solar Panel Deployment | 위성 패널 펼침 애니메이션 + 줌아웃 | ✅ 완료 |
| 3 | Satellite Position Adjustment | Y축 -136° 회전 + 카메라 추적 | ✅ 완료 |
| 4 | GEO Orbit Operation | 정지궤도 시연 (궤도선 + 지구 자전) | 🔲 미구현 |
| 5 | Orbit Type Comparison | LEO/MEO/Molniya 궤도 비교 시연 | 🔲 미구현 |

---

## Phase 4: GEO Orbit Operation (정지궤도 운행)

### 4-1. 카메라 전환
- SPACE 입력 → 카메라가 줌아웃하여 지구 전체 + 궤도가 보이는 위치로 이동
- 이동 중 카메라는 지구 중심을 look_at
- 최종 위치: 지구 옆 비스듬한 각도 (궤도면이 잘 보이도록)

### 4-2. 궤도 경로 시각화
- GEO 궤도를 원형 스플라인으로 표시 (적도면, 고도 ~35,786km)
- 시각적 스케일: 지구 반지름 대비 약 6.6배 (실제 비율) → 화면에 맞게 축소 조정
- **구현**: `ImmediateMesh` 또는 `MeshInstance3D` + `TorusMesh` (얇은 링)
- 궤도선 색상: 반투명 흰색 또는 시안

### 4-3. 위성 궤도 운행
- Satellite_parent를 GEO 궤도 위치로 이동
- 지구 자전 (Earth 노드 Y축 회전)
- 위성은 지구 자전과 동일 속도로 궤도를 공전 → 지구 표면 기준 정지 상태
- **핵심 표현**: 지구가 돌아도 위성이 항상 같은 지점 위에 머무는 것을 보여줌

### 4-4. UI
- 말풍선: "4. Geostationary Orbit (GEO)"
- 궤도 정보 표시: 고도 35,786 km / 주기 24h / 용도: 통신·기상

### 구현 파일
- `scripts/orbit_path.gd` — 궤도 경로 생성 및 렌더링
- `scripts/orbit_mover.gd` — 위성을 궤도 위에서 이동시키는 로직
- `demo_controller.gd` — Phase 4 상태 추가

---

## Phase 5: Orbit Type Comparison (궤도 유형 비교)

### 5-1. 궤도 유형 데이터

| 유형 | 고도 (km) | 주기 | 궤도 형태 | 경사각 | 실제 예시 |
|------|-----------|------|-----------|--------|-----------|
| GEO | 35,786 | 24h | 원형 | 0° | 천리안, 무궁화 |
| LEO | 400-800 | 90-100분 | 원형 | 51-98° | ISS, 스타링크 |
| MEO | 20,200 | 12h | 원형 | 55° | GPS |
| Molniya (HEO) | 600-39,700 | 12h | 타원형 (e≈0.72) | 63.4° | 몰니야 통신위성 |

### 5-2. 궤도 전환 조작
- **← → 방향키**: 궤도 유형 순차 전환 (GEO ↔ LEO ↔ MEO ↔ Molniya)
- 화면 하단에 현재 궤도 이름 + ← → 아이콘 표시
- 각 궤도 전환 시:
  - 이전 궤도선 페이드아웃 + 새 궤도선 페이드인
  - 위성이 새 궤도로 이동 후 공전 시작
  - 기존 말풍선(SatelliteCallout) 시스템으로 궤도 정보 표시

### 5-3. 궤도 정보 UI (기존 말풍선 시스템 활용)
- 위성에 연결된 말풍선(SatelliteCallout)에 궤도 명칭 + 설명 표시
- 궤도 전환 시 텍스트 페이드 전환
- 표시 내용 (영어):

| 궤도 | 말풍선 텍스트 |
|------|--------------|
| GEO | **Geostationary Orbit (GEO)**<br>Alt: 35,786 km · Period: 24h<br>Synced with Earth's rotation for fixed coverage |
| LEO | **Low Earth Orbit (LEO)**<br>Alt: 400-800 km · Period: 90 min<br>Fast orbiting for observation & communication |
| MEO | **Medium Earth Orbit (MEO)**<br>Alt: 20,200 km · Period: 12h<br>Navigation satellites like GPS |
| Molniya | **Molniya Orbit (HEO)**<br>Alt: 600-39,700 km · Period: 12h<br>Highly elliptical for polar region coverage |

### 5-4. 궤도별 시각화

**LEO (저궤도)**
- 지구 가까이 빠르게 공전 (GEO 대비 ~16배 빠름)
- 궤도면 경사 51° (ISS 기준)

**MEO (중궤도)**
- GEO와 LEO 사이, GPS 위성 시연
- 궤도면 경사 55°

**Molniya (고타원궤도)**
- 타원 궤도 렌더링 (원근점 차이가 큼)
- 근지점에서 빠르게, 원지점에서 느리게 이동 (케플러 제2법칙)
- 궤도면 경사 63.4°

### 5-5. 데모 종료
- 모든 궤도 시연 후 → 종료 UI 표시
- "Demo Complete" 메시지 + 전체 궤도를 동시에 보여주는 최종 화면

### 구현 파일
- `orbit_path.gd` 확장 — 타원 궤도 지원, 경사각 파라미터
- `orbit_mover.gd` 확장 — 타원 궤도 속도 변화 (케플러 근사)
- `scripts/orbit_data.gd` — 궤도 유형별 파라미터 딕셔너리
- `demo_controller.gd` — Phase 5 상태 추가

---

## Camera System (다중 카메라 전환)

Phase 4~5에서 활성화. **숫자키 1~5**로 카메라 뷰 전환.

| 키 | 뷰 이름 | 설명 |
|----|---------|------|
| 1 | Satellite Close-up | 위성 근접 촬영 (패널·안테나 디테일) |
| 2 | Orbit Side View | 궤도면 옆에서 바라보는 뷰 (궤도 형태 확인) |
| 3 | Earth Overview | 지구 정면 + 궤도 전체가 보이는 원경 |
| 4 | Top-down | 북극 위에서 내려다보는 뷰 (궤도 경사각 확인) |
| 5 | Tracking View | 위성 뒤에서 따라가는 추적 카메라 |

### 구현 방식
- 각 뷰는 사전 정의된 오프셋 + look_at 타겟 조합
- 전환 시 Tween으로 부드럽게 이동 (0.8초)
- Tracking View(5)는 매 프레임 위성 위치 추적
- 궤도 전환(← →)과 카메라 전환(1~5)은 독립적으로 동작

### 구현 파일
- `scripts/camera_rig.gd` — 카메라 뷰 프리셋 관리 + 전환 Tween
- 화면 좌상단에 현재 카메라 뷰 이름 표시 (예: "[1] Satellite Close-up")

### 키 매핑 요약 (Phase 4~5)

| 키 | 기능 |
|----|------|
| SPACE | 단계 진행 (Phase 전환) |
| ← → | 궤도 유형 전환 (Phase 5) |
| 1~5 | 카메라 뷰 전환 (Phase 4~5) |

---

## Implementation Plan (구현 순서)

### Step 1: 궤도 경로 시스템 (`orbit_path.gd`)
- [ ] 원형 궤도 경로 생성 (반지름, 경사각 파라미터)
- [ ] 타원 궤도 경로 생성 (장반경, 이심률, 경사각)
- [ ] ImmediateMesh로 3D 선 렌더링
- [ ] 페이드인/아웃 지원

### Step 2: 궤도 운동 시스템 (`orbit_mover.gd`)
- [ ] 원형 궤도: `pos = center + Vector3(cos(t), 0, sin(t)) * radius` + 경사 회전
- [ ] 타원 궤도: 케플러 방정식 근사 (mean anomaly → eccentric anomaly → true anomaly)
- [ ] 공전 속도 파라미터 (주기 기반)

### Step 3: 궤도 데이터 (`orbit_data.gd`)
- [ ] 각 궤도 유형별 파라미터 정의 (고도, 주기, 경사각, 이심률)
- [ ] 시각적 스케일 매핑 (실제 km → Godot 단위)
- [ ] 표시용 텍스트 (이름, 설명, 용도)

### Step 4: 카메라 시스템 (`camera_rig.gd`)
- [ ] 5개 카메라 뷰 프리셋 정의 (오프셋 + look_at 타겟)
- [ ] 숫자키 1~5 입력 → Tween 기반 뷰 전환
- [ ] Tracking View 매 프레임 위성 추적
- [ ] 화면 우상단 현재 뷰 이름 표시

### Step 5: Phase 4 구현
- [ ] demo_controller.gd에 WAIT_PHASE4, PHASE4_PLAYING 상태 추가
- [ ] 카메라 줌아웃 → 지구 전체 뷰
- [ ] GEO 궤도선 표시 + 위성 배치
- [ ] 지구 자전 + 위성 동기 공전 시연 (10~15초)
- [ ] 카메라 전환 활성화

### Step 6: Phase 5 구현
- [ ] demo_controller.gd에 WAIT_PHASE5, PHASE5_PLAYING 상태 추가
- [ ] ← → 방향키 궤도 전환 + 하단 UI
- [ ] LEO / MEO / Molniya 궤도 순차 시연
- [ ] 각 궤도별 위성 운동 시연 (각 10초)
- [ ] 종료 화면

---

## Scale Convention (스케일 규약) — 실측 완료

### 측정값
- 지구 모델 AABB: 1000 x 997 x 1000 (Mesh 기준)
- 지구 스케일: 0.8 → **실제 반지름(R) = 400 단위**
- 지구 위치: `(0, 0, 0)`
- Satellite_parent: `(0, 28, 498)` → 원점에서 **499 단위**
- 스케일 환산: **1 단위 ≈ 15.95 km** (400 단위 = 6,378 km)

### 실제 비율 궤도 반지름 (지구 중심 기준)

| 궤도 | 실제 (km) | Godot 실비율 | 비고 |
|------|----------|-------------|------|
| LEO | 6,778 | 425 | 지구 표면 바로 위, OK |
| MEO | 26,578 | 1,666 | 화면에서 너무 멀어짐 |
| GEO | 42,164 | 2,644 | 화면 밖으로 나감 |
| Molniya 근지점 | 6,978 | 438 | LEO와 비슷 |
| Molniya 원지점 | 46,078 | 2,890 | GEO보다 멀어짐 |

### 시각적 압축 스케일 (데모용)

실비율은 시각적으로 부적합하므로 교육 목적에 맞게 압축:

| 궤도 | 압축 반지름 (단위) | 지구 반지름 대비 |
|------|-------------------|-----------------|
| LEO | 480 | 1.2R |
| MEO | 700 | 1.75R |
| GEO | 950 | 2.375R |
| Molniya 근지점 | 480 | 1.2R |
| Molniya 원지점 | 1100 | 2.75R |

> 모든 궤도가 화면 내에서 구분 가능하면서 상대적 크기 관계를 유지

---

## Technical Notes

- **궤도 계산**: 물리 엔진 미사용, 파라메트릭 방정식 기반
- **케플러 근사**: 타원 궤도는 뉴턴-랩슨법으로 이심근점이각 계산
- **FBX 애니메이션**: "Take 001" — 패널 펼침
- **카메라**: intro_camera.gd (Phase 1) + demo_controller.gd (Phase 2~5)
- **UI**: CanvasLayer + unproject_position() 방식으로 3D 위치에 2D UI 고정
