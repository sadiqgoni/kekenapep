import 'package:keke_fairshare/index.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          buildOnboardingPage(
              context: context,
              image: 'assets/images/napep.webp',
              title: 'Welcome to KeKe FairShare',
              subtitle: 'Know the right fare, every ride'),
          buildOnboardingPage(
            context: context,
            image: 'assets/images/kekenapep.png',
            title: 'Easily Share and Check Fares',
            subtitle:
                'Access real-time fare information and contribute your own.',
          ),
          buildOnboardingPage(
            context: context,
            image: 'assets/images/filter.webp',
            title: 'Customize Your Fare Search',
            subtitle:
                'Filter fare data by date, route, and time for better insights.',
          ),
        ],
      ),
      bottomSheet: _currentPage != 2
          ? buildBottomSheet(screenWidth)
          : buildFinalBottomSheet(screenWidth),
    );
  }

  Widget buildOnboardingPage({
    required BuildContext context,
    required String image,
    required String title,
    required String subtitle,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: <Widget>[
          Container(
            height: screenHeight * 0.6,
            width: screenWidth * 0.9,
            margin: const EdgeInsets.only(top: 50),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.068,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.048,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomSheet(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextButton(
            onPressed: () {
              _pageController.animateToPage(2,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.linear);
            },
            child: Text(
              "SKIP",
              style:
                  TextStyle(color: Colors.black, fontSize: screenWidth * 0.038),
            ),
          ),
          Row(
            children: List.generate(3, (index) => buildDot(index)),
          ),
          TextButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.linear,
              );
            },
            child: Text(
              "NEXT",
              style:
                  TextStyle(color: Colors.black, fontSize: screenWidth * 0.038),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFinalBottomSheet(double screenWidth) {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            buildNavigationButton(
              text: "Register",
              screenWidth: screenWidth,
              isOutlined: false,
              onPressed: () {
                navigateTo(context, const RegisterScreen());
              },
            ),
            buildNavigationButton(
              text: "Sign in",
              screenWidth: screenWidth,
              isOutlined: true,
              onPressed: () {
                navigateTo(context, const SignInScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNavigationButton({
    required String text,
    required double screenWidth,
    required bool isOutlined,
    required VoidCallback onPressed,
  }) {
    return isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              side: const BorderSide(color: Color(0xFFFDB300)),
              padding: EdgeInsets.symmetric(
                vertical: screenWidth * 0.04,
                horizontal: screenWidth * 0.1,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.black),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDB300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: EdgeInsets.symmetric(
                vertical: screenWidth * 0.04,
                horizontal: screenWidth * 0.1,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.black),
            ),
          );
  }

  void navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget buildDot(int index) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFFFDB300) : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
