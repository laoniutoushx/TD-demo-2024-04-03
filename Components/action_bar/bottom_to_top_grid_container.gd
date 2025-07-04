# BottomToTopGridContainer.gd
extends Container
class_name BottomToTopGridContainer

@export var columns: int = 4
@export var expand_from_bottom: bool = true
@export var cell_padding: Vector2 = Vector2(5, 5)

func _get_minimum_size() -> Vector2:
    var cell_size := _get_max_child_size()
    var rows := ceil(get_child_count() / float(columns))
    return Vector2(columns * (cell_size.x + cell_padding.x), rows * (cell_size.y + cell_padding.y))

func _get_max_child_size() -> Vector2:
    var max_size := Vector2.ZERO
    for child in get_children():
        if child is Control and child.visible:
            max_size = max_size.max(child.get_combined_minimum_size())
    return max_size

func _sort_children():
    var visible_children := []
    for child in get_children():
        if child is Control and child.visible:
            visible_children.append(child)

    var cols := max(1, columns)
    var cell_size := _get_max_child_size()
    var rows := int(ceil(visible_children.size() / float(cols)))

    for i in range(visible_children.size()):
        var child := visible_children[i]
        var col := i % cols
        var row := i / cols

        # 向上扩张：反转行号
        if expand_from_bottom:
            row = rows - 1 - row

        var x := col * (cell_size.x + cell_padding.x)
        var y := row * (cell_size.y + cell_padding.y)

        child.position = Vector2(x, y)
        child.size = cell_size
