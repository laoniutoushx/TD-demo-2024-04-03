class_name DoublyLinkedList

var head: DoublyLinkedListNode = null
var tail: DoublyLinkedListNode = null
var size: int = 0

# 在链表头添加新节点
func add_to_head(value: Variant) -> void:
	var new_node = DoublyLinkedListNode.new(value)
	
	if head == null:
		head = new_node
		tail = new_node
	else:
		new_node.next_node = head
		head.prev_node = new_node
		head = new_node
	
	size += 1

# 在链表尾添加新节点
func add_to_tail(value: Variant) -> void:
	var new_node = DoublyLinkedListNode.new(value)
	
	if tail == null:
		head = new_node
		tail = new_node
	else:
		new_node.prev_node = tail
		tail.next_node = new_node
		tail = new_node
	
	size += 1

# 删除链表头节点
func remove_from_head() -> Variant:
	if head == null:
		return null

	var value = head.value
	
	if head == tail:
		head = null
		tail = null
	else:
		head = head.next_node
		head.prev_node = null
	
	size -= 1
	return value

# 删除链表尾节点
func remove_from_tail() -> Variant:
	if tail == null:
		return null

	var value = tail.value
	
	if head == tail:
		head = null
		tail = null
	else:
		tail = tail.prev_node
		tail.next_node = null
	
	size -= 1
	return value
	


# 删除指定的节点
func remove_node(node: DoublyLinkedListNode) -> void:
	if node == null:
		return
	
	if node == head:
		remove_from_head()
	elif node == tail:
		remove_from_tail()
	else:
		node.prev_node.next_node = node.next_node
		node.next_node.prev_node = node.prev_node
		size -= 1	


# 获取链表中的元素（按索引）
func got(index: int) -> Variant:
	if index < 0 or index >= size:
		return null

	var current: DoublyLinkedListNode
	
	# 从头开始遍历或从尾开始遍历，以提高效率
	if index < size / 2:
		current = head
		for i in range(index):
			current = current.next_node
	else:
		current = tail
		for i in range(size - index - 1):
			current = current.prev_node
	
	return current.value

# 打印链表中的所有元素
func print_list() -> void:
	var current = head
	while current != null:
		print(current.value)
		current = current.next_node

# 打印链表中的所有元素（逆向）
func print_list_reverse() -> void:
	var current = tail
	while current != null:
		print(current.value)
		current = current.prev_node


## 使用示例
#func _ready():
	#var doubly_linked_list = DoublyLinkedList.new()
#
	#doubly_linked_list.add_to_head(10)
	#doubly_linked_list.add_to_tail(20)
	#doubly_linked_list.add_to_tail(30)
	#
	#print("链表中的值 (正向):")
	#doubly_linked_list.print_list()  # 输出 10, 20, 30
#
	#print("链表中的值 (逆向):")
	#doubly_linked_list.print_list_reverse()  # 输出 30, 20, 10
#
	#print("删除头部:", doubly_linked_list.remove_from_head())  # 输出 10
	#doubly_linked_list.print_list()  # 输出 20, 30
#
	#print("删除尾部:", doubly_linked_list.remove_from_tail())  # 输出 30
	#doubly_linked_list.print_list()  # 输出 20
