import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';

class StelaScaffold extends StatelessWidget {
	final PreferredSizeWidget? appBar;
	final Widget body;
	final Widget? drawer;
	final Widget? bottomNavigationBar;
	final FloatingActionButton? floatingActionButton;
	final bool useGradientBackground;

	const StelaScaffold({
		super.key,
		this.appBar,
		required this.body,
		this.drawer,
		this.bottomNavigationBar,
		this.floatingActionButton,
		this.useGradientBackground = false,
	});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: appBar,
			drawer: drawer,
			bottomNavigationBar: bottomNavigationBar,
			floatingActionButton: floatingActionButton,
			backgroundColor: primaryWhite,
			body: useGradientBackground
					? Container(
							decoration: BoxDecoration(
								gradient: LinearGradient(
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
									colors: [
										primaryWhite,
										primaryButton.withValues(alpha: 0.12),
									],
								),
							),
							child: body,
						)
					: body,
		);
	}
}

class StelaAuthCard extends StatelessWidget {
	final Widget child;
	final double maxWidth;

	const StelaAuthCard({
		super.key,
		required this.child,
		this.maxWidth = 460,
	});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
				child: ConstrainedBox(
					constraints: BoxConstraints(maxWidth: maxWidth),
					child: Card(
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(20),
						),
						child: Padding(
							padding: const EdgeInsets.all(24),
							child: child,
						),
					),
				),
			),
		);
	}
}
