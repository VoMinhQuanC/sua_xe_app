import 'package:flutter/material.dart';
import '../../widgets/notification_bell.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> newsList = [
      {
        "title": "Bí quyết bảo dưỡng xe máy mùa mưa",
        "image": "assets/images/tintuc1.jpg",
        "desc":
            "Hướng dẫn cách bảo dưỡng xe hiệu quả trong mùa mưa giúp xe hoạt động ổn định và bền bỉ.",
      },
      {
        "title": "Khuyến mãi lớn tháng 4 tại VQTBike",
        "image": "assets/images/tintuc2.jpg",
        "desc":
            "Giảm giá đến 30% cho tất cả dịch vụ sửa xe và thay nhớt, chỉ áp dụng trong tháng 4 này!",
      },
      {
        "title": "TOP 5 loại nhớt tốt nhất cho xe tay ga",
        "image": "assets/images/tintuc3.jpg",
        "desc":
            "Chọn nhớt phù hợp sẽ giúp xe vận hành êm ái, tiết kiệm nhiên liệu và kéo dài tuổi thọ động cơ.",
      },
      {
        "title": "5 Dấu hiệu xe cần bảo dưỡng gấp",
        "image": "assets/images/tintuc4.jpg",
        "desc":
            "Những dấu hiệu cho thấy xe bạn đang gặp vấn đề và cần được kiểm tra ngay.",
      },
      {
        "title": "Lý do nên thay nhớt định kỳ",
        "image": "assets/images/tintuc5.jpg",
        "desc":
            "Thay nhớt định kỳ giúp động cơ xe luôn hoạt động tốt và giảm chi phí sửa chữa.",
      },
      {
        "title": "Cách bảo quản xe khi không sử dụng",
        "image": "assets/images/tintuc6.jpg",
        "desc":
            "Nếu bạn ít dùng xe, hãy đọc ngay hướng dẫn này để tránh hỏng hóc không đáng có.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Tin tức mới nhất",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          const NotificationBell(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72, // chỉnh tỉ lệ vừa đủ
                ),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final news = newsList[index];
                  return _buildNewsCard(context, news);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, String> news) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  news["image"]!,
                  height: constraints.maxHeight * 0.45, // linh hoạt theo card
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news["title"]!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          news["desc"]!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NewsDetailScreen(news: news),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Đọc tiếp",
                            style:
                                TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- Chi tiết bài viết ----------------
class NewsDetailScreen extends StatelessWidget {
  final Map<String, String> news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news["title"]!),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(news["image"]!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(
              news["title"]!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              news["desc"]!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}