# MyChefAI

MyChefAI is a Flutter-based mobile application that helps users discover, create, and share recipes. The app features a social cooking platform where users can follow other chefs, rate recipes, and build their culinary portfolio.

## Features

### Core Features
- **User Authentication**: Google Sign-in integration with Firebase
- **Recipe Management**: Create, view, and share recipes
- **Social Features**: Follow other chefs, view leaderboards
- **User Profiles**: Customizable profiles with chef ratings and statistics
- **Recipe Discovery**: Featured recipes and category-based browsing
- **Rating System**: Rate recipes and build your chef score

### Key Components
- **Home Screen**: Featured recipes, top chefs leaderboard, and quick actions
- **Recipe Screen**: Detailed recipe view with ingredients, instructions, and ratings
- **Profile Screen**: User information, recipes, followers, and editable profile sections
- **Search & Discovery**: Browse recipes by categories and ratings
- **Image Upload**: Profile picture management with Firebase Storage

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget (built-in)
- **UI Components**: Custom Material Design widgets

### Backend Services
- **Authentication**: Firebase Auth with Google Sign-in
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (for images)
- **Real-time Updates**: Firestore listeners

### Key Libraries
- `firebase_core: ^3.12.1`
- `firebase_auth: ^5.5.1`
- `cloud_firestore: ^5.6.5`
- `firebase_storage: ^12.4.4`
- `google_sign_in: ^6.1.5`
- `image_picker: ^1.1.2`

## Project Structure

```
lib/
├── components/          # Reusable UI components
│   ├── category_tags.dart
│   ├── cook_now_block.dart
│   ├── footer_nav_bar.dart
│   ├── google_sign_in_button.dart
│   ├── header_text.dart
│   ├── profile_block.dart
│   ├── rating_block.dart
│   ├── recipe_block.dart
│   ├── recipe_title_bar.dart
│   ├── text_card.dart
│   └── title_bar.dart
├── models/             # Data models
│   ├── nutrition.dart
│   ├── profile.dart
│   └── recipe.dart
├── screens/            # App screens
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── onboarding_screen.dart
│   ├── profile_screen.dart
│   └── recipe_screen.dart
├── services/           # Business logic services
│   ├── auth_service.dart
│   ├── profile_service.dart
│   ├── recipe_service.dart
│   └── storage_service.dart
├── firebase_options.dart
└── main.dart
```

## Setup Instructions

1. **Prerequisites**
   - Flutter SDK (^3.7.0)
   - Dart SDK
   - Android Studio / VS Code
   - Firebase account

2. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mychefai
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Firebase Setup**
   - Create a new Firebase project
   - Add iOS and Android apps to your Firebase project
   - Download and add configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
   - Enable Authentication (Google Sign-in)
   - Set up Firestore Database
   - Set up Firebase Storage

5. **Run the app**
   ```bash
   flutter run
   ```

## Key Features Implementation

### Authentication Flow
1. User opens app → Login Screen
2. Google Sign-in → Check if profile exists
3. If no profile → Onboarding Screen
4. If profile exists → Home Screen

### Profile Management
- Editable fields: About, Location, Dietary Restrictions
- Profile picture upload to Firebase Storage
- Real-time updates to Firestore
- Chef rating system based on recipe reviews

### Recipe System
- Recipe creation with ingredients and instructions
- Category tagging (max 5 tags)
- Nutrition information
- Rating and favoriting system
- Public/private visibility options

### Social Features
- Follow/unfollow users
- Top chefs leaderboard
- Recipe feed from followed users
- User search functionality

## Database Structure

### Collections

**profiles**
```json
{
  "id": "string",
  "uid": "string",
  "username": "string",
  "email": "string",
  "profilePicture": "string",
  "description": "string",
  "region": "string",
  "chefScore": "number",
  "numberOfReviews": "number",
  "dietaryRestrictions": "string",
  "myRecipes": "array",
  "myFavorites": "array",
  "followers": "number",
  "isFollowing": "boolean"
}
```

**recipes**
```json
{
  "id": "string",
  "title": "string",
  "image": "string",
  "ingredients": "array",
  "instructions": "array",
  "categoryTags": "array",
  "creator": "object",
  "averageRating": "number",
  "numberOfRatings": "number",
  "numberOfFavorites": "number",
  "nutritionInfo": "object",
  "isPublic": "boolean",
  "isFavorited": "boolean"
}
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Future Enhancements

- [ ] Recipe search functionality
- [ ] Advanced filtering options
- [ ] Social sharing features
- [ ] Push notifications
- [ ] Offline mode support
- [ ] Recipe collections/cookbooks
- [ ] Meal planning features
- [ ] Shopping list generation
- [ ] Video recipe uploads
- [ ] Multi-language support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors and testers

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.

---

Made with ❤️ using Flutter