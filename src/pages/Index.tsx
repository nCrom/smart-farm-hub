
import { Header } from "../components/layout/Header";
import { WeatherCard } from "../components/dashboard/WeatherCard";
import { DeviceOverview } from "../components/dashboard/DeviceOverview";
import { useState } from "react";

const Index = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 via-blue-50 to-orange-50">
      <Header isMenuOpen={isMenuOpen} onMenuOpenChange={setIsMenuOpen} />
      <main className="pt-32 p-6">
        <div className="max-w-7xl mx-auto space-y-8">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2">
              <div className="space-y-2 mb-8">
                <h1 className="text-4xl font-bold text-blue-900">
                  작물 생육정보와 환경정보에 대한
                </h1>
                <div>
                  <span className="text-4xl font-bold text-blue-600">데이터를 기반으로</span>
                </div>
                <div>
                  <span className="text-4xl font-bold text-green-600">최적 생육환경을 조성</span>
                </div>
              </div>
              <DeviceOverview />
            </div>
            <div className="lg:col-span-1">
              <WeatherCard />
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Index;
