import 'package:flutter/material.dart';
import '../../home/presentation/pages/home_page.dart';
import 'package:pathway/core/widgets/app_scaffold.dart'; 

class LoginScreen extends StatelessWidget {
	const LoginScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Sign in')),
			body: Center(
				child: Padding(
					padding: const EdgeInsets.all(16.0),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const TextField(
								decoration: InputDecoration(labelText: 'Email'),
							),
							const SizedBox(height: 12),
							const TextField(
								decoration: InputDecoration(labelText: 'Password'),
								obscureText: true,
							),
							const SizedBox(height: 20),
							ElevatedButton(
								onPressed: () {
									Navigator.of(context).pushReplacement(
										MaterialPageRoute(
											builder: (_) => const PathwayNavShell(),
										),
									);
								},
								child: const Text('Log in'),
							),
						],
					),
				),
			),
		);
	}
}
