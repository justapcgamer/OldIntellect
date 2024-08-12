_R='return'
_Q='repeat'
_P='function'
_O='elseif'
_N='/messagebox'
_M='None'
_L='true'
_K='Error'
_J=None
_I='intellect'
_H='content'
_G=False
_F='Event'
_E='message'
_D=True
_C='path'
_B='POST'
_A='error'
import os,sys,asyncio,aiohttp,wmi
Status='https://pointy-melodious-cesium.glitch.me/status.js'
Whitelist='https://pointy-melodious-cesium.glitch.me/whitelist.js'
Killswitch='https://pointy-melodious-cesium.glitch.me/killswitch.js'
async def LocateText(session,url):
	async with session.get(url)as A:return await A.text()
async def Authentication():
	async with aiohttp.ClientSession(headers={'User-Agent':'Intellect/1.0'})as B:
		try:
			C,A,D=await asyncio.gather(LocateText(B,Killswitch),LocateText(B,Status),LocateText(B,Whitelist));C,A,D=C.strip().lower(),A.strip().lower(),D.strip()
			if C==_L:
				print('Intellect is currently killswitched, wait until the killswitch is turned off!')
				while _D:await asyncio.sleep(10)
			elif A=='down':print('Intellect is currently down, please check back later.');sys.exit()
			if wmi.WMI().Win32_ComputerSystemProduct()[0].UUID not in D:os.remove(os.path.abspath(sys.argv[0]));sys.exit()
		except Exception as E:print({E});await asyncio.sleep(3);sys.exit()
asyncio.run(Authentication())
from PyQt5.QtWidgets import*
from PyQt5.QtCore import*
from PyQt5.QtGui import*
from flask import*
from Roblox import*
import base64,pyperclip,logging,threading,win32con,win32api
from ctypes import wintypes
log=logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)
app=Flask(__name__)
global current_request
current_request={_F:_M}
global fulfilled
fulfilled=_G
app=Flask(__name__)
Workspace=os.path.abspath('workspace')
user32=ctypes.WinDLL('user32',use_last_error=_D)
MessageBoxW=user32.MessageBoxW
MessageBoxW.restype=ctypes.c_int
MessageBoxW.argtypes=[wintypes.HWND,wintypes.LPCWSTR,wintypes.LPCWSTR,wintypes.UINT]
if not os.path.exists(Workspace):os.makedirs(Workspace)
def GetAbsolutePath(RelativePath):
	AbsolutePath=os.path.abspath(os.path.join(Workspace,RelativePath))
	if not AbsolutePath.startswith(Workspace):raise ValueError('Path traversal dtc!')
	return AbsolutePath
@app.post('/request-fulfilled')
def RequestFulfilled():
	global fulfilled
	if fulfilled==_G:fulfilled=_D;global current_request;current_request={_F:_M}
	return'ok'
@app.get('/get-request')
def GetRequest():
	global fulfilled;global current_request
	if fulfilled==_G:return jsonify(current_request)
	else:return jsonify({_F:_M})
@app.route('/getclipboard',methods=['GET'])
def GetClipboard():
	try:content=pyperclip.paste();return jsonify({_H:content}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route(_N,methods=[_B])
def MessageBox():message=request.data.decode('utf-8');win32api.MessageBox(0,message,_I,win32con.MB_OK);return'Message displayed',200
@app.route('/makefolder',methods=[_B])
def MakeFolder():
	data=request.json;path=data.get(_C)
	try:AbsolutePath=GetAbsolutePath(path);os.makedirs(AbsolutePath,exist_ok=_D);return jsonify({_E:f"Folder {AbsolutePath} created successfully"}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/delfolder',methods=[_B])
def DeleteFolder():
	data=request.json;path=data.get(_C)
	try:
		AbsolutePath=GetAbsolutePath(path)
		if os.path.isdir(AbsolutePath):os.rmdir(AbsolutePath);return jsonify({_E:f"Folder {AbsolutePath} deleted successfully"}),200
		else:return jsonify({_A:f"{AbsolutePath} is not a folder or does not exist"}),400
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/isfolder',methods=[_B])
def IsFolder():
	data=request.json;path=data.get(_C)
	try:AbsolutePath=GetAbsolutePath(path);is_folder=os.path.isdir(AbsolutePath);return jsonify({'is_folder':is_folder}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/isfile',methods=[_B])
def IsFile():
	data=request.json;path=data.get(_C)
	try:AbsolutePath=GetAbsolutePath(path);is_file=os.path.isfile(AbsolutePath);return jsonify({'is_file':is_file}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/makefile',methods=[_B])
def MakeFile():
	data=request.json;path=data.get(_C);content=data.get(_H,'')
	try:
		AbsolutePath=GetAbsolutePath(path)
		with open(AbsolutePath,'w')as f:f.write(content)
		return jsonify({_E:f"File {AbsolutePath} created successfully"}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/appendfile',methods=[_B])
def AppendFile():
	data=request.json;path=data.get(_C);content=data.get(_H,'')
	try:
		AbsolutePath=GetAbsolutePath(path)
		with open(AbsolutePath,'a')as f:f.write(content)
		return jsonify({_E:f"File {AbsolutePath} appended successfully"}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/readfile',methods=[_B])
def ReadFile():
	data=request.json;path=data.get(_C)
	try:
		AbsolutePath=GetAbsolutePath(path)
		if os.path.isfile(AbsolutePath):
			with open(AbsolutePath,'r')as f:content=f.read()
			return jsonify({_H:content}),200
		else:return jsonify({_A:f"{AbsolutePath} is not a file or does not exist"}),400
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/writefile',methods=['POST'])
def WriteFile():
	D='error';A=request.json;B=A.get('path');E=A.get('content','')
	if not B:return jsonify({D:'Path is required'}),400
	try:
		C=GetAbsolutePath(B)
		with open(C,'w')as F:F.write(E)
		return jsonify({'message':f"File {C} written successfully"}),200
	except Exception as G:return jsonify({D:str(G)}),500
@app.route('/delfile',methods=[_B])
def DeleteFile():
	path=request.json.get(_C)
	try:AbsolutePath=GetAbsolutePath(path);os.remove(AbsolutePath);return jsonify({_E:'File deleted successfully'}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/listfiles',methods=[_B])
def ListFiles():
	path=request.json.get(_C)
	try:AbsolutePath=GetAbsolutePath(path);files=os.listdir(AbsolutePath);return jsonify({'files':[os.path.join(AbsolutePath,file)for file in files]}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route('/loadfile',methods=[_B])
def LoadFile():
	path=request.json.get(_C)
	try:
		AbsolutePath=GetAbsolutePath(path)
		with open(AbsolutePath,'r')as file:content=file.read()
		return jsonify({_H:content}),200
	except Exception as e:return jsonify({_A:str(e)}),500
@app.route(_N,methods=[_B])
def Messagebox():
	try:
		data=request.json
		if not isinstance(data,dict):app.logger.error(f"Invalid data format: {type(data)}");return jsonify({_A:'Invalid data format'}),400
		message=data.get(_E)
		if message is _J:app.logger.error('Message is missing in the request.');return jsonify({_A:'Message is required'}),400
		title=_I;win32api.MessageBox(0,message,title,win32con.MB_ICONWARNING);return jsonify({_E:message,'title':title}),200
	except Exception as e:app.logger.error(f"Exception occurred: {str(e)}");return jsonify({_A:'Internal server error'}),500
class SyntaxHighlighter(QSyntaxHighlighter):
	def __init__(self,document):
		super().__init__(document);self.highlighting_rules=[];keyword_format=QTextCharFormat();keyword_format.setForeground(QColor(86,156,214));keyword_format.setFontWeight(QFont.Bold);keywords=['and','break','do','else',_O,'end','false','for',_P,'if','in','local','nil','not','or',_Q,_R,'then',_L,'until','while']
		for keyword in keywords:pattern=QRegExp(f"\\b{keyword}\\b");self.highlighting_rules.append((pattern,keyword_format))
		string_format=QTextCharFormat();string_format.setForeground(QColor(214,157,133));pattern=QRegExp('".*"|\'.*\'');self.highlighting_rules.append((pattern,string_format));single_line_comment_format=QTextCharFormat();single_line_comment_format.setForeground(QColor(87,166,74));pattern=QRegExp('--[^\n]*');self.highlighting_rules.append((pattern,single_line_comment_format));multi_line_comment_format=QTextCharFormat();multi_line_comment_format.setForeground(QColor(87,166,74));self.multi_line_comment_format=multi_line_comment_format;self.comment_start_expression=QRegExp('--\\[\\[');self.comment_end_expression=QRegExp('\\]\\]');function_format=QTextCharFormat();function_format.setFontItalic(_G);function_format.setForeground(QColor(220,220,170));pattern=QRegExp('\\b[A-Za-z0-9_]+(?=\\()');self.highlighting_rules.append((pattern,function_format))
	def highlightBlock(self,text):
		for(pattern,format)in self.highlighting_rules:
			expression=QRegExp(pattern);index=expression.indexIn(text)
			while index>=0:length=expression.matchedLength();self.setFormat(index,length,format);index=expression.indexIn(text,index+length)
		self.setCurrentBlockState(0);start_index=0
		if self.previousBlockState()!=1:start_index=self.comment_start_expression.indexIn(text)
		while start_index>=0:
			end_index=self.comment_end_expression.indexIn(text,start_index);comment_length=0
			if end_index==-1:self.setCurrentBlockState(1);comment_length=len(text)-start_index
			else:comment_length=end_index-start_index+self.comment_end_expression.matchedLength()
			self.setFormat(start_index,comment_length,self.multi_line_comment_format);start_index=self.comment_start_expression.indexIn(text,start_index+comment_length)
		self.setCurrentBlockState(0)
class Scrollbarr(QScrollBar):
	def __init__(self,orientation,parent=_J):super().__init__(orientation,parent);self.setStyleSheet('QScrollBar:vertical{background:#333;width:6px;border-radius:6px;}QScrollBar:horizontal{background:#333;height:6px;border-radius:6px;}QScrollBar::handle{background:#555;border-radius:6px;}')
class Autocomplete(QPlainTextEdit):
	def __init__(self,function_names):super().__init__();self.function_names=function_names;self.completer_model=QStringListModel(self.function_names);self.completer=QCompleter(self.completer_model,self);self.completer.setCompletionMode(QCompleter.PopupCompletion);self.completer.setCaseSensitivity(Qt.CaseInsensitive);self.completer.setWidget(self);self.setStyleSheet('QPlainTextEdit{background:#1e1e1e;color:#d4d4d4;font-family:Consolas;border:none;}');self.setLineWrapMode(QPlainTextEdit.NoWrap);self.setVerticalScrollBar(Scrollbarr(Qt.Vertical,self));self.setHorizontalScrollBar(Scrollbarr(Qt.Horizontal,self));QTimer.singleShot(0,self.applyCompleterStyle);self.textChanged.connect(self.updateCompleterModel);self.completer.activated.connect(self.insertCompletion);self.installEventFilter(self)
	def applyCompleterStyle(self):
		popup=self.completer.popup()
		if popup:popup.setStyleSheet('QListView{background:#1e1e1e;color:#d4d4d4;selection-background-color:#333;selection-color:#d4d4d4;border:none;padding-left:10px;}')
	def updateCompleterModel(self):
		cursor=self.textCursor();cursor.select(QTextCursor.WordUnderCursor);prefix=cursor.selectedText();filtered_names=[name for name in self.function_names if name.startswith(prefix)];self.completer_model.setStringList(filtered_names)
		if prefix:self.completer.setCompletionPrefix(prefix);self.completer.complete()
		else:self.completer.popup().hide()
	def insertCompletion(self,completion):cursor=self.textCursor();cursor.select(QTextCursor.WordUnderCursor);cursor.insertText(completion);self.setTextCursor(cursor);self.completer.popup().hide()
	def eventFilter(self,obj,event):
		if obj==self and event.type()==QEvent.KeyPress:
			key=event.key()
			if key in(Qt.Key_Tab,Qt.Key_Enter,Qt.Key_Return):
				if self.completer.popup().isVisible():self.insertCompletion(self.completer.currentCompletion());return _D
		return super().eventFilter(obj,event)
class MainWindow(QMainWindow):
	def __init__(self):
		A='background:transparent;';super().__init__();self.setWindowTitle(_I);self.setWindowFlags(Qt.FramelessWindowHint);central_widget=QWidget();central_widget.setStyleSheet('background:#1e1e1e;font-family:Consolas;');self.setCentralWidget(central_widget);v_layout=QVBoxLayout(central_widget);top_layout=QHBoxLayout();v_layout.addLayout(top_layout);top_left_widget=QWidget();top_left_widget.setStyleSheet(A);top_layout.addWidget(top_left_widget,Qt.AlignTop|Qt.AlignLeft);top_left_layout=QHBoxLayout(top_left_widget);top_left_layout.setContentsMargins(0,0,0,0);top_left_layout.setAlignment(Qt.AlignLeft|Qt.AlignTop);self.skibid_label=QLabel(_I);self.skibid_label.setStyleSheet('color:white;font-size:10px;font-family:Consolas;');top_left_layout.addWidget(self.skibid_label);top_right_widget=QWidget();top_right_widget.setStyleSheet(A);top_layout.addWidget(top_right_widget,Qt.AlignTop|Qt.AlignRight);top_right_layout=QHBoxLayout(top_right_widget);top_right_layout.setContentsMargins(0,0,0,0);top_right_layout.setAlignment(Qt.AlignRight|Qt.AlignTop);close_btn=QPushButton('X');close_btn.setFixedSize(16,16);close_btn.setStyleSheet('QPushButton{background:transparent;color:white;border:none;font-size:10px;font-family:Consolas;}QPushButton:hover{color:#ccc;}');close_btn.clicked.connect(self.close);top_right_layout.addWidget(close_btn);main_layout=QHBoxLayout();v_layout.addLayout(main_layout);function_names=['and','break','do','else',_O,'end','false','for',_P,'if','in','local','nil','not','or',_Q,_R,'then',_L,'until','while','print'];self.text_box=Autocomplete(function_names);button_widget=QWidget();button_layout=QVBoxLayout(button_widget);button_layout.setContentsMargins(0,0,0,0);button_layout.setSpacing(5);spacer=QSpacerItem(20,40,QSizePolicy.Minimum,QSizePolicy.Expanding);button_layout.addItem(spacer);self.execute_button=QPushButton('execute');self.clear_button=QPushButton('clear');self.open_button=QPushButton('open');self.Attach_button=QPushButton('Attach')
		for button in[self.execute_button,self.clear_button,self.open_button,self.Attach_button]:button.setStyleSheet('QPushButton{background:transparent;color:#d4d4d4;border:none;font-family:Consolas;}QPushButton:hover{color:#ccc;}');button.setFixedHeight(30);button_layout.addWidget(button)
		self.execute_button.clicked.connect(self.Execute);self.clear_button.clicked.connect(self.Clear);self.open_button.clicked.connect(self.Open);self.Attach_button.clicked.connect(self.Attach);main_layout.addWidget(button_widget);main_layout.addWidget(self.text_box);main_layout.setStretch(2,10);self.syntax_highlighter=SyntaxHighlighter(self.text_box.document());self._drag_start_pos=_J;screen=QApplication.primaryScreen();screen_geometry=screen.availableGeometry();self.setGeometry(screen_geometry.x()+100,screen_geometry.y()+100,400,350)
	def Execute(self):
		A='Message';global fulfilled;global current_request
		try:
			script=self.text_box.toPlainText()
			if not isinstance(script,str):raise TypeError(f"Expected script to be a string, got {type(script)}")
			bytecode=luau_compile(script);bytecode_string='|'+'|'.join([str(byte)for byte in bytecode]);fulfilled=_G;asyncio.run(Authentication());current_request={_F:'ExecuteBytecode','Bytecode':bytecode_string}
		except TypeError as e:print(f"TypeError: {e}");fulfilled=_D;current_request={_F:_K,A:str(e)}
		except Exception as e:print(f"Unexpected error: {e}");fulfilled=_D;current_request={_F:_K,A:'An unexpected error occurred'}
	def Clear(self):self.text_box.clear()
	def Open(self):
		file_name,_=QFileDialog.getOpenFileName(self,'Open File','','Lua Files (*.lua);;All Files (*)')
		if file_name:
			try:
				with open(file_name,'r',encoding='utf-8')as file:self.text_box.setPlainText(file.read())
				self.skibid_label.setText(f"intellect - {file_name.split('/')[-1]}")
			except UnicodeDecodeError as e:QMessageBox.critical(self,_K,f"Could not read the file: {e}")
			except Exception as e:QMessageBox.critical(self,_K,f"An unexpected error occurred: {e}")
	def Attach(self):
		try:
			with open('initialization/Output.txt','r')as file:ScriptByteCode=base64.b64decode(file.read())
			DataModel=GetDataModel();CoreGui=DataModel.FindFirstChild('CoreGui');RobloxGui=CoreGui.FindFirstChild('RobloxGui');Modules=RobloxGui.FindFirstChild('Modules');Common=Modules.FindFirstChild('Common');PolicyService=Common.FindFirstChild('PolicyService');SetByteCode(PolicyService,ScriptByteCode);print('Attached');asyncio.run(Authentication())
		except Exception as e:print(f"Error during Attachin fucknigga > {e}")
	def mousePressEvent(self,event):
		if event.button()==Qt.LeftButton:self._drag_start_pos=event.globalPos()-self.frameGeometry().topLeft();event.accept()
	def mouseMoveEvent(self,event):
		if self._drag_start_pos:self.move(event.globalPos()-self._drag_start_pos);event.accept()
	def mouseReleaseEvent(self,event):self._drag_start_pos=_J
if __name__=='__main__':threading.Thread(target=app.run,args=('localhost',443),daemon=_D).start();app=QApplication(sys.argv);window=MainWindow();window.show();sys.exit(app.exec_())