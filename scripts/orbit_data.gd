class_name OrbitData

## 궤도 유형별 파라미터 정의.
## 시각적 압축 스케일 적용 (지구 반지름 R=400 기준).

const EARTH_RADIUS := 400.0

enum OrbitType { GEO, LEO, MEO, MOLNIYA }

class OrbitParams:
	var name: String
	var radius: float            # 원형 궤도 반지름 (Godot 단위)
	var semi_major: float        # 타원 장반경
	var eccentricity: float      # 이심률 (0=원형)
	var inclination_deg: float   # 경사각 (도)
	var period_seconds: float    # 데모 내 공전 주기 (초) — 실제 비율 아님
	var color: Color
	var title: String
	var description: String

	func _init(p_name: String, p_radius: float, p_ecc: float, p_incl: float,
			p_period: float, p_color: Color, p_title: String, p_desc: String,
			p_semi_major: float = 0.0) -> void:
		name = p_name
		radius = p_radius
		eccentricity = p_ecc
		inclination_deg = p_incl
		period_seconds = p_period
		color = p_color
		title = p_title
		description = p_desc
		semi_major = p_semi_major if p_semi_major > 0.0 else p_radius


static func get_orbit(type: OrbitType) -> OrbitParams:
	match type:
		OrbitType.GEO:
			return OrbitParams.new(
				"GEO", 950.0, 0.0, 0.0, 30.0,
				Color(0.2, 0.8, 1.0, 0.8),
				"Geostationary Orbit (GEO)",
				"Alt: 35,786 km  |  Period: 24h\nSynced with Earth's rotation\nfor fixed coverage")
		OrbitType.LEO:
			return OrbitParams.new(
				"LEO", 480.0, 0.0, 51.6, 8.0,
				Color(0.2, 1.0, 0.4, 0.8),
				"Low Earth Orbit (LEO)",
				"Alt: 400 km  |  Period: 90 min\nFast orbiting for observation\n& communication (ISS, Starlink)")
		OrbitType.MEO:
			return OrbitParams.new(
				"MEO", 700.0, 0.0, 55.0, 16.0,
				Color(1.0, 0.8, 0.2, 0.8),
				"Medium Earth Orbit (MEO)",
				"Alt: 20,200 km  |  Period: 12h\nNavigation satellites\nlike GPS")
		OrbitType.MOLNIYA:
			# 압축 스케일: 근지점 480, 원지점 1100
			# a=(480+1100)/2=790, e=(1100-480)/(1100+480)=0.392
			return OrbitParams.new(
				"Molniya", 0.0, 0.392, 63.4, 20.0,
				Color(1.0, 0.4, 0.3, 0.8),
				"Molniya Orbit (HEO)",
				"Alt: 600-39,700 km  |  Period: 12h\nHighly elliptical for\npolar region coverage",
				790.0)  # semi_major
		_:
			return get_orbit(OrbitType.GEO)


static func get_all_types() -> Array[OrbitType]:
	return [OrbitType.GEO, OrbitType.LEO, OrbitType.MEO, OrbitType.MOLNIYA]
