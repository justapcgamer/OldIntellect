_F=b' size: '
_E='ModuleScript'
_D='LOCALAPPDATA'
_C='rb'
_B='ignore'
_A='utf-8'
import regex as re,os,time,glob,shutil,ctypes
from API import GetProcesses,Memory
for process in GetProcesses():
	if process.name=='RobloxPlayerBeta.exe':process_id=process.id;break
else:print('intellect>open roblox');time.sleep(2)
memory=Memory()
memory.OpenProcess(process_id)
RBXPath=os.getenv(_D)+'\\Roblox\\logs'
class Offsets:Name=72;Parent=96;Children=80;ClassDescriptor=24;LocalPlayer=256;ClassName=8;StringValue=192;Bytecode={'LocalScript':440,_E:336}
def CleanLogs(Directory):
	B=Directory
	for C in os.listdir(B):
		A=os.path.join(B,C)
		if os.path.isfile(A):os.unlink(A)
		elif os.path.isdir(A):shutil.rmtree(A)
while True:
	try:CleanLogs(RBXPath);break
	except Exception as e:break
def GetDataModel():
	E=os.path.join(os.environ[_D],'Roblox','logs');C=[]
	for A in glob.glob(os.path.join(E,'*')):
		if A.endswith('.log')and'_Player_'in A:C.append(A)
	F=max(C,key=os.path.getctime);G='\\[FLog::SurfaceController\\] SurfaceController\\[_:\\d\\]::initialize view\\([A-F0-9]{16}\\)';H=re.compile(G);B=[]
	with open(F,'r',encoding=_A,errors=_B)as A:
		for D in A.read().splitlines():
			if H.search(D):B.append(int(D.split(']::initialize view(')[1].split(')')[0],16))
	if not B:raise Exception('No valid Addresses found in log file.')
	for I in B:J=memory.ReadLongLong(I+280);K=memory.ReadLongLong(J+408);return Instance(K)
def GetName(Address):
	A=memory.ReadLongLong(Address+Offsets.Name);B=memory.ReadINT(A+16)
	if B>15:A=memory.ReadLongLong(A)
	C=memory.ReadBytes(A,B);return C.decode()
def GetChildren(Address):
	B=memory.ReadLongLong(Address+Offsets.Children);D=memory.ReadLongLong(B+0);E=memory.ReadLongLong(B+8)-16;A=D;C=[]
	while A<=E:C.append(memory.ReadLongLong(A));A+=16
	return C
class Instance:
	def __init__(A,Address):B=Address;A.Address=B;A.Name=GetName(B);C=memory.ReadLongLong(A.Address+Offsets.ClassDescriptor);A.ClassName=A.ReadClassName(C+Offsets.ClassName)
	def RBXString(B):
		try:
			A=Memory.ReadINT(B+16)
			if A<0 or A>1024:return
			if A<16:return Memory.ReadBytes(B,A).decode(_A)
			else:C=Memory.ReadLongLong(B);return Memory.ReadBytes(C,A).decode(_A)
		except Exception as D:return
	def ReadClassName(D,Address):
		A=Address;B=memory.ReadINT(A+16)
		if B>=16:A=memory.ReadLongLong(A)
		C=memory.ReadBytes(A,B);return C.decode()
	def GetChildren(A):return[Instance(A)for A in GetChildren(A.Address)]
	def FindFirstChild(B,name):
		for A in B.GetChildren():
			if A.Name==name:return A
	def FindFirstChildOfClass(B,class_name):
		C=B.GetChildren()
		for A in C:
			if A.ClassName==class_name:return A
	def WaitForChild(B,name,timeout=None):
		while True:
			for A in B.GetChildren():
				if A.Name==name:return A
	@property
	def Value(self):
		A=self.Address+Offsets.StringValue;B=memory.ReadLong(A+16)
		if B>15:A=memory.ReadLongLong(A)
		return memory.ReadBytes(A,B).decode()
def SetByteCode(script,ScriptByteCode):A=ScriptByteCode;B=len(A);C=memory.ReadLongLong(script.Address+Offsets.Bytecode[_E]);D=memory.AllocateMemory(B);memory.WriteBytes(D,A);memory.WriteLong(C+16,D);memory.WriteLong(C+32,B)
def SetValue(instance,value):
	F=b'\x00';A=instance;B=value.encode()+F;C=len(B);D=A.Address+Offsets.StringValue;print('[intellect] -> [Debug] -> [Roblox] -> [Bridge] -> [Bytecode] -> Before -> ',A.Value)
	if C<=15:G=B.ljust(16,F);memory.WriteBytes(D,G)
	else:E=memory.AllocateMemory(C);memory.WriteBytes(E,B);memory.WriteLong(D,E)
	memory.WriteINT(D+16,C);print('[intellect] -> [Debug] -> [Roblox] -> [Bridge] -> [Bytecode] ->  ',A.Value)
dll=ctypes.CDLL('./bin/API.dll')
RBXCompile_t=dll.RBXCompile
RBXCompile_t.argtypes=[ctypes.c_char_p,ctypes.c_char_p]
RBXDecompress_t=dll.RBXDecompress
RBXDecompress_t.argtypes=[ctypes.c_char_p,ctypes.c_char_p]
class Bytecode:
	def Compile(D,path='compressed.btc'):
		A=path;RBXCompile_t(A.encode(errors=_B),D.encode(errors=_B))
		try:
			with open(A,_C)as B:B=open(A,_C);C=B.read().split(_F);B.close()
		except:pass
		os.remove(A);return[C[0],int(C[1])]
	def Decompress(D,path='decompressed.btc'):
		A=path;RBXDecompress_t(A.encode(errors=_B),D)
		try:
			with open(A,_C)as B:B=open(A,_C);C=B.read().split(_F);B.close()
		except:pass
		os.remove(A)
		if len(C)>1:return[C[0],int(C[1])]
		else:return[None,-1]
luau=ctypes.CDLL('./bin/Compiler.dll')
class lua_CompileOptions(ctypes.Structure):_fields_=[('optimizationLevel',ctypes.c_int),('debugLevel',ctypes.c_int),('typeInfoLevel',ctypes.c_int),('coverageLevel',ctypes.c_int),('vectorLib',ctypes.c_char_p),('vectorCtor',ctypes.c_char_p),('vectorType',ctypes.c_char_p),('mutableGlobals',ctypes.POINTER(ctypes.c_char_p)),('userdataTypes',ctypes.POINTER(ctypes.c_char_p))]
luau_compile_func=luau.luau_compile
luau_compile_func.restype=ctypes.POINTER(ctypes.c_char)
luau_compile_func.argtypes=[ctypes.c_char_p,ctypes.c_size_t,ctypes.POINTER(lua_CompileOptions),ctypes.POINTER(ctypes.c_size_t)]
default_options=lua_CompileOptions(optimizationLevel=2,debugLevel=1)
def luau_compile(code,options=default_options):
	A=code
	if not isinstance(A,str):raise TypeError(f"Expected code to be a string, got {type(A)}")
	B=A.encode(_A);C=ctypes.c_size_t();D=luau_compile_func(B,len(B),ctypes.byref(options),ctypes.byref(C));return bytes(D[:C.value])