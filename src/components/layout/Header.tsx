
import { Bell, Search, User, Menu, X } from "lucide-react";
import { Link } from "react-router-dom";

const menuItems = [{
  label: "대시보드",
  path: "/"
}, {
  label: "디바이스 관리",
  path: "/devices"
}, {
  label: "데이터 분석",
  path: "/analytics"
}, {
  label: "커뮤니티",
  path: "/community"
}, {
  label: "교육 자료",
  path: "/education"
}, {
  label: "스마트팜 마켓",
  path: "/market"
}, {
  label: "문의하기",
  path: "/support"
}, {
  label: "설정",
  path: "/settings"
}];

interface HeaderProps {
  isMenuOpen: boolean;
  onMenuOpenChange: (isOpen: boolean) => void;
}

export function Header({
  isMenuOpen,
  onMenuOpenChange
}: HeaderProps) {
  return <>
      <header className="bg-white/80 backdrop-blur-sm border-b border-gray-200 fixed top-0 right-0 left-0 z-20">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-8">
              <h1 className="text-xl font-bold text-primary-600">스마트팜 파밍</h1>
              <div className="hidden md:flex items-center gap-4">
                {menuItems.map(item => <Link key={item.path} to={item.path} className="flex items-center gap-2 px-3 py-2 text-gray-700 rounded-lg hover:bg-primary-50 hover:text-primary-600 transition-all">
                    <span className="text-sm font-medium">{item.label}</span>
                  </Link>)}
              </div>
            </div>
            <div className="flex items-center gap-4">
              <button className="p-2 hover:bg-gray-100 rounded-full transition-all relative">
                <Bell className="w-5 h-5 text-gray-600" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-full transition-all">
                <User className="w-5 h-5 text-gray-600" />
              </button>
              <button onClick={() => onMenuOpenChange(!isMenuOpen)} className="p-2 hover:bg-gray-100 rounded-lg transition-all md:hidden">
                {isMenuOpen ? <X className="w-6 h-6 text-gray-600" /> : <Menu className="w-6 h-6 text-gray-600" />}
              </button>
            </div>
          </div>
          <div className="flex items-center gap-4 w-full max-w-md mx-auto py-3">
            <Search className="w-5 h-5 text-gray-400" />
            <input type="text" placeholder="검색어를 입력하세요..." className="w-full bg-gray-50/50 border border-gray-200 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-all" />
          </div>
        </div>
      </header>

      {/* 모바일 메뉴 */}
      {isMenuOpen && <div className="fixed inset-0 z-10 md:hidden">
          <div className="fixed inset-0 bg-black/50" onClick={() => onMenuOpenChange(false)} />
          <div className="fixed top-16 left-0 right-0 bottom-0 bg-white z-20 overflow-y-auto">
            <div className="p-4">
              <div className="flex items-center gap-4 w-full mb-4">
                <Search className="w-5 h-5 text-gray-400" />
                <input type="text" placeholder="검색어를 입력하세요..." className="w-full bg-gray-50/50 border border-gray-200 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-all" />
              </div>
              <nav>
                {menuItems.map(item => <Link key={item.path} to={item.path} onClick={() => onMenuOpenChange(false)} className="flex items-center gap-3 px-4 py-3 text-gray-700 hover:bg-primary-50 hover:text-primary-600 transition-all rounded-lg">
                    <span className="font-medium">{item.label}</span>
                  </Link>)}
              </nav>
            </div>
          </div>
        </div>}
    </>;
}
