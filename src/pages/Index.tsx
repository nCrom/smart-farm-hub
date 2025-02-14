
import { Sidebar } from "../components/layout/Sidebar";
import { Header } from "../components/layout/Header";
import { WeatherCard } from "../components/dashboard/WeatherCard";
import { DeviceOverview } from "../components/dashboard/DeviceOverview";

const Index = () => {
  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar />
      <Header />
      <main className="pl-64 pt-16 p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          <h1 className="text-3xl font-bold text-gray-900">스마트팜 대시보드</h1>
          <WeatherCard />
          <DeviceOverview />
        </div>
      </main>
    </div>
  );
};

export default Index;
