_B='Length'
_A=True
import ctypes,enum as Enumeration, time
from ctypes import*
from ctypes.wintypes import*
from dataclasses import dataclass
NTSTATUS=ctypes.c_ulong
HANDLE=HANDLE
PVOID=ctypes.c_void_p
ULONG=ctypes.c_ulong
ULONG_PTR=ctypes.POINTER(ULONG)
USHORT=ctypes.c_ushort
SIZE_T=ctypes.c_size_t
PSIZE_T=ctypes.POINTER(SIZE_T)
NT_SUCCESS=lambda status:status>=0
STATUS_INFO_LENGTH_MISMATCH=3221225476
NtCurrentProcess=HANDLE(-1)
ProcessHandleType=7
SystemHandleInformation=16
PROCESS_PRIORITY_CLASS=1048576
THREAD_BASE_PRIORITY=16
LIST_MODULES_ALL=3
SeDebugPriv=20
PWSTR=LPWSTR
ACCESS_MASK=DWORD
BOOLEAN=BOOL
LPVOID=ctypes.c_void_p
HMODULE=LPVOID
TH32CS_INHERIT=2147483648
TH32CS_SNAPHEAPLIST=1
TH32CS_SNAPMODULE=8
TH32CS_SNAPMODULE32=16
TH32CS_SNAPPROCESS=2
TH32CS_SNAPTHREAD=4
TH32CS_SNAPALL=TH32CS_SNAPHEAPLIST|TH32CS_SNAPMODULE|TH32CS_SNAPPROCESS|TH32CS_SNAPTHREAD
MEM_COMMIT=4096
MEM_RESERVE=8192
MEM_RESET=524288
MEM_RESET_UNDO=16777216
MEM_LARGE_PAGES=536870912
PAGE_EXECUTE=16
PAGE_EXECUTE_READ=32
PAGE_EXECUTE_READWRITE=64
PAGE_EXECUTE_WRITECOPY=128
PAGE_NOACCESS=1
PAGE_READONLY=2
PAGE_READWRITE=4
PAGE_WRITECOPY=8
PAGE_TARGETS_INVALID=1073741824
PAGE_TARGETS_NO_UPDATE=1073741824
PAGE_GUARD=256
PAGE_NOCACHE=512
PAGE_WRITECOMBINE=1024
PROCESS_CREATE_PROCESS=128
PROCESS_CREATE_THREAD=2
PROCESS_DUP_HANDLE=64
PROCESS_QUERY_INFORMATION=1024
PROCESS_QUERY_LIMITED_INFORMATION=4096
PROCESS_SET_INFORMATION=512
PROCESS_SET_QUOTA=256
PROCESS_SUSPEND_RESUME=2048
PROCESS_TERMINATE=1
PROCESS_VM_OPERATION=8
PROCESS_VM_READ=16
PROCESS_VM_WRITE=32
SYNCHRONIZE=1048576
STANDARD_RIGHTS_REQUIRED=983040
PROCESS_ALL_ACCESS=STANDARD_RIGHTS_REQUIRED|SYNCHRONIZE|65535
class PROCESSENTRY32(Structure):_fields_=[('dwSize',DWORD),('cntUsage',DWORD),('th32ProcessID',DWORD),('th32DefaultHeapID',ULONG_PTR),('th32ModuleID',DWORD),('cntThreads',DWORD),('th32ParentProcessID',DWORD),('pcPriClassBase',LONG),('dwFlags',DWORD),('szExeFile',CHAR*260)]
class MEMORY_BASIC_INFORMATION(ctypes.Structure):_fields_=[('BaseAddress',ctypes.c_ulonglong),('AllocationBase',ctypes.c_ulonglong),('AllocationProtect',ctypes.c_ulong),('__alignment1',ctypes.c_ulong),('RegionSize',ctypes.c_ulonglong),('State',ctypes.c_ulong),('Protect',ctypes.c_ulong),('Type',ctypes.c_ulong),('__alignment2',ctypes.c_ulong)]
class UNICODE_STRING(ctypes.Structure):_fields_=[(_B,USHORT),('MaximumLength',USHORT),('Buffer',PWSTR)]
class OBJECT_ATTRIBUTES(ctypes.Structure):_fields_=[(_B,ULONG),('RootDirectory',HANDLE),('ObjectName',ctypes.POINTER(UNICODE_STRING)),('Attributes',ULONG),('SecurityDescriptor',PVOID),('SecurityQualityOfService',PVOID)]
class CLIENT_ID(ctypes.Structure):_fields_=[('UniqueProcess',PVOID),('UniqueThread',PVOID)]
class SYSTEM_HANDLE_TABLE_ENTRY_INFO(ctypes.Structure):_fields_=[('ProcessId',ULONG),('ObjectTypeNumber',ctypes.c_byte),('Flags',ctypes.c_byte),('Handle',ctypes.c_ushort),('Object',PVOID),('GrantedAccess',ACCESS_MASK)]
class SYSTEM_HANDLE_INFORMATION(ctypes.Structure):_fields_=[('HandleCount',ULONG),('Handles',SYSTEM_HANDLE_TABLE_ENTRY_INFO*1)]
class MEMORY_STATE(Enumeration.IntEnum):MEM_COMMIT=4096;MEM_FREE=65536;MEM_RESERVE=8192;MEM_DECOMMIT=16384;MEM_RELEASE=32768
class MEMORY_TYPES(Enumeration.IntEnum):MEM_IMAGE=16777216;MEM_MAPPED=262144;MEM_PRIVATE=131072
LPPROCESSENTRY32=POINTER(PROCESSENTRY32)
kernel32=ctypes.WinDLL('Kernel32.dll',use_last_error=_A)
ntdll=ctypes.WinDLL('Ntdll.dll',use_last_error=_A)
VirtualAllocEx=kernel32.VirtualAllocEx
VirtualAllocEx.restype=PVOID
OpenProcess=kernel32.OpenProcess
OpenProcess.argtypes=[DWORD,BOOL,DWORD]
OpenProcess.restype=HANDLE
CreateToolhelp32Snapshot=kernel32.CreateToolhelp32Snapshot
CreateToolhelp32Snapshot.argtypes=[DWORD,DWORD]
CreateToolhelp32Snapshot.restype=HANDLE
Process32First=kernel32.Process32First
Process32First.argtypes=[HANDLE,LPPROCESSENTRY32]
Process32First.restype=BOOL
Process32Next=kernel32.Process32Next
Process32Next.argtypes=[HANDLE,LPPROCESSENTRY32]
Process32Next.restype=BOOL
ntdll=ctypes.WinDLL('ntdll.dll',use_last_error=_A)
NtAllocateVirtualMemory=ntdll.NtAllocateVirtualMemory
NtAllocateVirtualMemory.argtypes=[HANDLE,PVOID,ULONG_PTR,PSIZE_T,ULONG,ULONG]
@dataclass
class Process:id:int;name:str
def GetProcesses():
	pe32=PROCESSENTRY32();pe32.dwSize=sizeof(pe32);hProcessSnap=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);process_list=[];Process32First(hProcessSnap,ctypes.byref(pe32));process_list.append(Process(pe32.th32ProcessID,pe32.szExeFile.decode()))
	while Process32Next(hProcessSnap,ctypes.byref(pe32)):process_list.append(Process(pe32.th32ProcessID,pe32.szExeFile.decode()))
	return process_list
class Memory:
    def __init__(self):
        self.ProcessHandle = PVOID(0)

    def OpenProcess(self, id):
        handle = OpenProcess(DWORD(PROCESS_ALL_ACCESS), BOOL(_A), DWORD(id))
        self.ProcessHandle = HANDLE(handle)

    def Suspend(self):
        ntdll.NtSuspendProcess(self.ProcessHandle)

    def Resume(self):
        ntdll.NtResumeProcess(self.ProcessHandle)

    def IsPhysicalMemory(self, Address):
        MBI = MEMORY_BASIC_INFORMATION()
        Size = ctypes.sizeof(MEMORY_BASIC_INFORMATION)
        if kernel32.VirtualQueryEx(ctypes.c_void_p(Address), ctypes.byref(MBI), Size) == Size:
            if MBI.State == MEMORY_STATE.MEM_COMMIT:
                if MBI.Type == MEMORY_TYPES.MEM_MAPPED:
                    return _A
                if MBI.Type == MEMORY_TYPES.MEM_PRIVATE:
                    return _A
        return False

    def IsMemoryValid(self, Address):
        MBI = MEMORY_BASIC_INFORMATION()
        Result = kernel32.VirtualQueryEx(self.ProcessHandle, ctypes.c_void_p(Address), ctypes.byref(MBI), ctypes.sizeof(MBI))
        return Result != 0 and MBI.State == MEMORY_STATE.MEM_COMMIT

    def Read(self, address, ctype):
        buffer = ctype()
        for i in range(5):
            if not self.IsMemoryValid(address) or not self.IsPhysicalMemory(address):
                i += 1
            else:
                break
        status = kernel32.ReadProcessMemory(self.ProcessHandle, PVOID(address), ctypes.byref(buffer), ULONG(sizeof(buffer)), None)
        if not status:
            raise ctypes.WinError(ctypes.get_last_error())
        return buffer

    def ReadLongLong(self, address):
        return self.Read(address, ctypes.c_ulonglong).value

    def ReadBytes(self, address, size):
        return self.Read(address, ctypes.c_char * size).raw

    def ReadINT(self, address):
        return self.Read(address, ctypes.c_int64).value

    def ReadLong(self, address):
        return self.Read(address, ctypes.c_long).value

    def ReadFloat(self, address):
        return self.Read(address, ctypes.c_float).value

    def AllocateMemory(self, size, address=None):
        return VirtualAllocEx(self.ProcessHandle, PVOID(address), SIZE_T(size), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)

    def Write(self, address, value):
        for i in range(5):
            if not self.IsMemoryValid(address) or not self.IsPhysicalMemory(address):
                i += 1
            else:
                break
        size = ctypes.sizeof(value)
        status = kernel32.WriteProcessMemory(self.ProcessHandle, PVOID(address), ctypes.pointer(value), size, None)
        if not status:
            raise ctypes.WinError(ctypes.get_last_error())
        return status

    def WriteBytes(self, address, value):
        value = (len(value) * ctypes.c_char)(*value)
        return self.Write(address, value)

    def WriteLongLong(self, address, value):
        value = ctypes.c_longlong(value)
        return self.Write(address, value)

    def WriteLong(self, address, value):
        value = ctypes.c_long(value)
        return self.Write(address, value)

    def WriteINT(self, address, value):
        value = ctypes.c_int(value)
        return self.Write(address, value)