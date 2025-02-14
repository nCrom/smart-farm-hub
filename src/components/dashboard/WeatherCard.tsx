
import { CloudRain, Thermometer, Wind } from "lucide-react";

export function WeatherCard() {
  return (
    <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm hover:shadow-md transition-all animate-fadeIn">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">현재 날씨</h3>
        <span className="text-sm text-gray-500">서울</span>
      </div>
      <div className="flex items-center gap-6">
        <div className="flex items-center gap-2">
          <Thermometer className="w-5 h-5 text-orange-500" />
          <span className="text-2xl font-bold">24°C</span>
        </div>
        <div className="flex items-center gap-2">
          <CloudRain className="w-5 h-5 text-blue-500" />
          <span className="text-gray-600">60%</span>
        </div>
        <div className="flex items-center gap-2">
          <Wind className="w-5 h-5 text-gray-500" />
          <span className="text-gray-600">3m/s</span>
        </div>
      </div>
    </div>
  );
}
