import 'package:flutter/material.dart';
import 'package:stater_example/widgets/app.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Stater Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.withConverters),
                child: const Text('With Converters'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.noConverters),
                child: const Text('No Converters'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.splitScreen),
                child: const Text('Split Screen'),
              ),
            ],
          ),
        ));
  }
}
