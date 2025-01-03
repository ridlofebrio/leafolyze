import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leafolyze/blocs/article/article_bloc.dart';
import 'package:leafolyze/blocs/article/article_event.dart';
import 'package:leafolyze/blocs/auth/auth_bloc.dart';
import 'package:leafolyze/blocs/auth/auth_event.dart';
import 'package:leafolyze/blocs/history/history_bloc.dart';
import 'package:leafolyze/blocs/history/history_event.dart';
import 'package:leafolyze/blocs/product/product_bloc.dart';
import 'package:leafolyze/blocs/product/product_event.dart';
import 'package:leafolyze/blocs/profile/profile_bloc.dart';
import 'package:leafolyze/blocs/shop/shop_bloc.dart';
import 'package:leafolyze/config/router.dart';
import 'package:leafolyze/models/auth_token.dart';
import 'package:leafolyze/repositories/article_repository.dart';
import 'package:leafolyze/repositories/auth_repository.dart';
import 'package:leafolyze/repositories/detection_repository.dart';
import 'package:leafolyze/repositories/product_repository.dart';
import 'package:leafolyze/repositories/profile_repository.dart';
import 'package:leafolyze/repositories/shop_repository.dart';
import 'package:leafolyze/services/api_service.dart';
import 'package:leafolyze/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AuthRepository authRepository;

  final storageService = await StorageService.init();
  final apiService = ApiService(
      storageService, (AuthToken token) => authRepository.refresh(token));
  authRepository = AuthRepository(apiService, storageService);

  runApp(MainApp(
      authRepository: authRepository,
      storageService: storageService,
      apiService: apiService));
}

class MainApp extends StatelessWidget {
  final AuthRepository authRepository;
  final StorageService storageService;
  final ApiService apiService;

  const MainApp(
      {super.key,
      required this.authRepository,
      required this.storageService,
      required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider<ApiService>(create: (context) => apiService),
        RepositoryProvider<StorageService>(create: (context) => storageService),
        RepositoryProvider<ArticleRepository>(
          create: (context) => ArticleRepository(
            context.read<ApiService>(),
            context.read<StorageService>(),
          ),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(
            context.read<ApiService>(),
            context.read<StorageService>(),
          ),
        ),
        RepositoryProvider<DetectionRepository>(
          create: (context) => DetectionRepository(
            context.read<ApiService>(),
            context.read<StorageService>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(authRepository, storageService)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => ArticleBloc(context.read<ArticleRepository>())
              ..add(LoadArticles()),
          ),
          BlocProvider(
            create: (context) => ProfileBloc(
              repository: context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => HistoryBloc(
              context.read<DetectionRepository>(),
            )..add(LoadDetections()),
          ),
          BlocProvider(
            create: (context) => ProductBloc(
              ProductRepository(apiService, storageService),
            )..add(LoadProducts()),
          ),
          BlocProvider(
            create: (context) =>
                ShopBloc(ShopRepository(apiService, storageService)),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Leafolyze',
          theme: ThemeData(
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            primarySwatch: Colors.green,
            useMaterial3: true,
          ),
          routerConfig: goRouter,
        ),
      ),
    );
  }
}
