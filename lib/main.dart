import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dompetiq',
      routes: {'/': (context) => MyHomePage()},
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            color: Colors.blueAccent,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://avatars.githubusercontent.com/u/118288247?v=4&size=64',
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),

                          Text(
                            'Erlangga Hidayatullah',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.settings, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Active Balance',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '\$217.871,88',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text('Account: 142-423-123-444'),
                                Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          IconButton.filled(
                                            onPressed: () {},
                                            icon: Icon(Icons.add),
                                            style: IconButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Income",
                                            style: TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // IconButton(
                                    //   icon: Icon(Icons.trending_up),
                                    //   onPressed: () {
                                    //     debugPrint('edit');
                                    //   },
                                    // ),
                                    // IconButton(
                                    //   icon: Icon(Icons.trending_down),
                                    //   onPressed: () {
                                    //     debugPrint('edit');
                                    //   },
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
