import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../view_models/content_view_model.dart';

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<ContentViewModel>().clearLog();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Consumer<ContentViewModel>(
          builder: (context, vm, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              height: double.infinity,
              color: Colors.black87,
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  vm.log.isEmpty ? l10n.logEmpty : vm.log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
