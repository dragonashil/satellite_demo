# Satellite Demo - Scene Settings

## Project Settings (project.godot)

| 항목 | 값 |
|------|-----|
| 엔진 버전 | Godot 4.6 |
| 렌더링 파이프라인 | Forward Plus |
| 렌더링 드라이버 (Windows) | D3D12 |
| 물리 엔진 | Jolt Physics |
| 메인 씬 | `res://main.tscn` |

## Main Scene 구조 (main.tscn)

```
Main (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── Earth
├── Satellite_parent (MeshInstance3D)
│   └── Satellite
└── Camera3D
```

## 노드별 설정

### WorldEnvironment
- Background Mode: Sky (2)
- Sky Material: PanoramaSkyMaterial
- Panorama Texture: `res://assets/AllSkyFree_Godot-10e858fef0a9c5fa071de8bc191c3b4bef00edda/Screenshots/_0002_AllSkyFree_Screen_07.jpg`

### DirectionalLight3D
- Position: (0, 198.347, 772.811)
- Rotation: Transform3D(0.866, -0.250, 0.433, 0, 0.866, 0.500, -0.500, -0.433, 0.750, ...)
- Light Energy: 1.5
- Shadow: enabled

### Earth
- Model: `res://assets/3d/earth/Earth_1_12756.glb`
- Transform (회전 적용됨):
  ```
  Transform3D(
    0.477, -0.000, 0.642,
    0.333,  0.684, -0.248,
   -0.549,  0.415,  0.408,
    0, 0, 0
  )
  ```

### Satellite_parent (MeshInstance3D)
- Position: (0, 0, 498.460)

### Satellite
- Model: `res://assets/3d/satellite/satellite_re.fbx`
- Transform: 기본값 (부모 노드 기준 로컬 원점)

### Camera3D
- Position: (0, 69.935, 526.462)
- Rotation: 약간 아래를 향함 (약 -13.4도)
- FOV: 50.0
