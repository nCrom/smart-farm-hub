
import { Bell, Search, User } from "lucide-react";

export function Header() {
  return (
    <header className="h-16 bg-white/80 backdrop-blur-sm border-b border-gray-200 fixed top-0 right-0 left-64 z-10 animate-fadeIn">
      <div className="flex items-center justify-between h-full px-6">
        <div className="flex items-center gap-4 w-96">
          <Search className="w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="검색어를 입력하세요..."
            className="w-full bg-gray-50/50 border border-gray-200 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-all"
          />
        </div>
        <div className="flex items-center gap-6">
          <div className="text-sm text-gray-600">
            26분 29초
            <span className="ml-2 text-blue-600">연결하기</span>
          </div>
          <button className="p-2 hover:bg-gray-100 rounded-full transition-all relative">
            <Bell className="w-5 h-5 text-gray-600" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>
          <button className="p-2 hover:bg-gray-100 rounded-full transition-all">
            <User className="w-5 h-5 text-gray-600" />
          </button>
        </div>
      </div>
    </header>
  );
}
