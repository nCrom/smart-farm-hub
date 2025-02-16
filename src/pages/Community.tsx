
import { useState } from "react";
import { Header } from "../components/layout/Header";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { MessageSquare, ThumbsUp, Users } from "lucide-react";

// 임시 게시글 데이터
const posts = [
  {
    id: 1,
    title: "스마트팜 초보자입니다. 질문이 있습니다.",
    author: "김농부",
    date: "2024-02-20",
    views: 123,
    likes: 15,
    comments: 8,
    category: "질문/답변",
  },
  {
    id: 2,
    title: "양상추 수경재배 성공 노하우 공유",
    author: "박재배",
    date: "2024-02-19",
    views: 432,
    likes: 67,
    comments: 23,
    category: "노하우 공유",
  },
  {
    id: 3,
    title: "3월 스마트팜 오프라인 모임 안내",
    author: "이모임",
    date: "2024-02-18",
    views: 221,
    likes: 28,
    comments: 12,
    category: "모임/이벤트",
  },
];

const Community = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 via-blue-50 to-orange-50">
      <Header isMenuOpen={isMenuOpen} onMenuOpenChange={setIsMenuOpen} />
      <main className="pt-24 p-6">
        <div className="max-w-7xl mx-auto space-y-8">
          <div className="flex justify-between items-center">
            <h1 className="text-3xl font-bold text-gray-900">커뮤니티</h1>
            <button className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors">
              글쓰기
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {posts.map((post) => (
              <Card key={post.id} className="hover:shadow-lg transition-shadow">
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <span className="inline-block px-2 py-1 text-xs font-medium text-primary-700 bg-primary-50 rounded-full mb-2">
                        {post.category}
                      </span>
                      <CardTitle className="text-lg font-bold hover:text-primary-600 cursor-pointer">
                        {post.title}
                      </CardTitle>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center text-sm text-gray-500 space-x-4">
                    <span>{post.author}</span>
                    <span>{post.date}</span>
                  </div>
                  <div className="flex items-center space-x-4 mt-4 text-sm text-gray-600">
                    <div className="flex items-center space-x-1">
                      <Users className="w-4 h-4" />
                      <span>{post.views}</span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <ThumbsUp className="w-4 h-4" />
                      <span>{post.likes}</span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <MessageSquare className="w-4 h-4" />
                      <span>{post.comments}</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
};

export default Community;
