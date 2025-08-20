extends Buff




func _ready() -> void:
    super._ready()

    # 监听 wave start
    SignalBus.wave_start.connect(_on_wave_start)



func _on_wave_start(wave_index: int, wave_resource: WaveResource, wave_resources: Array) -> void:
    
    
    # 增加当前 wave * 100 money
    SOS.main.player_controller.set_money(unit, SOS.main.player_controller.money + (wave_index * 100 + 100) )

    # # 创建贪婪特效 for unit
    # var greedy_vfx: Node3D = SOS.main.vfx_system.create_vfx("greedy", unit)
    # if greedy_vfx != null:
    #     greedy_vfx.name = "greedy_vfx"