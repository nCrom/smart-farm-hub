
import { Home, Settings, Sprout, BarChart3, Users, ShoppingBag, BookOpen, MessageSquare } from "lucide-react";
import { Link } from "react-router-dom";

const menuItems = [
  { icon: Home, label: "대시보드", path: "/" },
  { icon: Sprout, label: "디바이스 관리", path: "/devices" },
  { icon: BarChart3, label: "데이터 분석", path: "/analytics" },
  { icon: Users, label: "커뮤니티", path: "/community" },
  { icon: BookOpen, label: "교육 자료", path: "/education" },
  { icon: ShoppingBag, label: "스마트팜 마켓", path: "/market" },
  { icon: MessageSquare, label: "문의하기", path: "/support" },
  { icon: Settings, label: "설정", path: "/settings" },
];

export function Sidebar() {
  return (
    <nav className="w-64 bg-white/80 backdrop-blur-sm border-r border-gray-200 h-screen fixed left-0 top-0 overflow-y-auto animate-fadeIn">
      <div className="p-6">
        <h1 className="text-2xl font-bold text-primary-600">스마트팜 허브</h1>
      </div>
      <div className="px-4">
        {menuItems.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-primary-50 hover:text-primary-600 transition-all"
          >
            <item.icon className="w-5 h-5" />
            <span className="font-medium">{item.label}</span>
          </Link>
        ))}
      </div>
    </nav>
  );
}
