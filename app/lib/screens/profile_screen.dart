import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.arrow_back, size: 16),
          ),
          onPressed: () {},
        ),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'PRO',
                style: TextStyle(
                  color: Color(0xFF004AAD),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: 'FILE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.settings, size: 16),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.share, size: 16),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Profile avatar
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.person, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Username dots
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('•', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('•', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('•', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 20),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Color(0xFF004AAD),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Color(0xFF004AAD),
                borderRadius: BorderRadius.circular(8),
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_on),
                      SizedBox(width: 8),
                      Text('Videos', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark),
                      SizedBox(width: 8),
                      Text('Saved', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Videos tab
                GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 0, // Empty state
                  itemBuilder: (context, index) {
                    return Container(
                      color: Color(0xFF003377),
                      child: const Center(
                        child: Icon(Icons.play_circle_outline),
                      ),
                    );
                  },
                ),
                // Saved tab
                GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 0, // Empty state
                  itemBuilder: (context, index) {
                    return Container(
                      color: Color(0xFF003377),
                      child: const Center(
                        child: Icon(Icons.bookmark),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}