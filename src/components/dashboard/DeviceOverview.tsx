
import { Activity, Droplet, Sun, Thermometer } from "lucide-react";

export function DeviceOverview() {
  const devices = [
    { name: "온도 센서", value: "26°C", icon: Thermometer, color: "text-red-500" },
    { name: "습도 센서", value: "65%", icon: Droplet, color: "text-blue-500" },
    { name: "조도 센서", value: "800 lux", icon: Sun, color: "text-yellow-500" },
    { name: "EC 센서", value: "1.2 mS/cm", icon: Activity, color: "text-green-500" },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {devices.map((device) => (
        <div key={device.name} className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm hover:shadow-md transition-all animate-fadeIn">
          <div className="flex items-center gap-4">
            <div className={`p-3 rounded-full bg-gray-50 ${device.color}`}>
              <device.icon className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <p className="text-sm text-gray-500 mb-1">{device.name}</p>
              <p className="text-2xl font-bold">{device.value}</p>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
