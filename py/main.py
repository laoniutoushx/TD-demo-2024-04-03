import sys
from PyQt5.QtWidgets import QApplication
from godot_tres_editor.views import TresEditor

if __name__ == "__main__":
    app = QApplication(sys.argv)
    editor = TresEditor()
    editor.show()
    sys.exit(app.exec_())