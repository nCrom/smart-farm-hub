
import { Home, Settings, Sprout, BarChart3, Users, BookOpen, MessageSquare } from "lucide-react";
import { Link } from "react-router-dom";

const menuItems = [
  { icon: Home, label: "스마트팜 이란", path: "/about" },
  { icon: Sprout, label: "지원사업", path: "/support" },
  { icon: BookOpen, label: "스마트팜 교육", path: "/education" },
  { icon: MessageSquare, label: "알림소식", path: "/news" },
  { icon: Users, label: "고객지원", path: "/customer" },
];

export function Sidebar() {
  return (
    <nav className="w-64 bg-white/80 backdrop-blur-sm border-r border-gray-200 h-screen fixed left-0 top-0 overflow-y-auto animate-fadeIn">
      <div className="p-6">
        <h1 className="text-2xl font-bold text-primary-600">스마트팜코리아</h1>
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
