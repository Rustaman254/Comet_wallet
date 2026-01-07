# KYC Implementation Guide

This document outlines the production-ready KYC (Know Your Customer) implementation for the Comet Wallet application.

## Architecture Overview

### Components

1. **KYC Service** (`lib/services/kyc_service.dart`)
   - Handles image uploads to Cradle Voices server
   - Manages KYC data submission to backend API
   - Complete KYC workflow orchestration

2. **KYC Model** (`lib/models/kyc_model.dart`)
   - Data structure for KYC information
   - JSON serialization/deserialization

3. **ID Upload Screen** (`lib/screens/kyc/id_upload_screen.dart`)
   - Real camera integration for ID front capture
   - Real camera integration for ID back capture
   - Image preview and retake functionality
   - Production-ready error handling

4. **Liveness Check Screen** (`lib/screens/kyc/liveness_check_screen.dart`)
   - Front camera selfie capture
   - Real-time camera preview
   - Production-ready error handling

## API Endpoints

### Constants
- **Base URL**: `https://api.yeshara.network/api/v1`
- **KYC Endpoint**: `{{BASE_URL}}/kyc/create`
- **Image Upload URL**: `https://images.cradlevoices.com/`

### KYC Create Endpoint

**POST** `/api/v1/kyc/create`

**Payload Structure:**
```json
{
  "KYC": {
    "userID": 12,
    "ID_document": "https://images.cradlevoices.com/uploads/...",
    "ID_document_back": "https://images.cradlevoices.com/uploads/...",
    "KRA_document": "https://images.cradlevoices.com/uploads/...",
    "profile_photo": "https://images.cradlevoices.com/uploads/...",
    "proof_of_address": "https://images.cradlevoices.com/uploads/..."
  }
}
```

### Image Upload Endpoint

**POST** `/uploads`

- Host: `https://images.cradlevoices.com/`
- Method: `multipart/form-data`
- Field name: `file`
- Returns: Image URL in response

## Workflow

### KYC Process Flow

```
KYCIntroScreen
    ↓
IDUploadScreen (Front ID)
    ↓
IDUploadScreen (Back ID)
    ↓
LivenessCheckScreen (Selfie)
    ↓
HomeScreen (Complete)
```

### ID Capture Process

1. **Instruction Screen**: User sees instructions for ID capture
2. **Camera Screen**: Real camera preview with ID frame guide
3. **Capture**: User taps camera button to capture image
4. **Preview**: User reviews captured image
5. **Confirm/Retake**: User confirms or retakes the photo
6. **Repeat**: Process repeats for back side

### Selfie Capture Process

1. **Instructions**: User sees selfie capture instructions
2. **Camera**: Front camera preview with face oval guide
3. **Capture**: User taps button to capture selfie
4. **Success**: Image captured, user navigated to home

## Dependencies

### Required Packages

```yaml
dependencies:
  camera: ^0.10.5          # Camera functionality
  http: ^1.2.0             # HTTP requests
  google_fonts: ^6.1.0     # Custom fonts
  shared_preferences: ^2.2.2
  qr_flutter: ^4.1.0
  mobile_scanner: ^7.1.4
```

## Usage Example

### Complete KYC Flow

```dart
import 'dart:io';
import 'package:comet_wallet/services/kyc_service.dart';

// After capturing all images (idFront, idBack, kra, profile, address)
final result = await KYCService.completeKYC(
  userID: userId,
  idFrontImage: File(frontImagePath),
  idBackImage: File(backImagePath),
  kraDocument: File(kraPath),
  profilePhoto: File(profilePhotoPath),
  proofOfAddress: File(proofOfAddressPath),
);

if (result['success']) {
  print('KYC submitted successfully');
}
```

### Upload Single Image

```dart
final imageUrl = await KYCService.uploadImage(
  File(imagePath),
);
```

### Submit KYC Data

```dart
import 'package:comet_wallet/models/kyc_model.dart';

final kycData = KYCData(
  userID: 12,
  idDocumentFront: 'https://...',
  idDocumentBack: 'https://...',
  kraDocument: 'https://...',
  profilePhoto: 'https://...',
  proofOfAddress: 'https://...',
);

final response = await KYCService.submitKYC(kycData);
```

## Production Considerations

### Error Handling
- Camera initialization failures
- Network request timeouts
- Image upload failures
- API validation errors
- Device camera permissions

### Security
- Images are uploaded to secure Cradle Voices server
- HTTPS communication for all API calls
- User data is transmitted securely
- No local storage of sensitive images

### Performance
- High resolution camera presets for clear captures
- Efficient image handling
- Minimal memory footprint
- Proper resource cleanup in dispose methods

### User Experience
- Clear visual guides for ID capture (frame overlay)
- Face oval guide for selfie capture
- Real-time camera preview
- Feedback through toast notifications
- Ability to retake photos
- Loading indicators during processing

## Permissions Required

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture your ID and selfie for KYC verification.</string>
```

## Testing

### Test Scenarios

1. **Camera Initialization**
   - Verify camera initializes correctly
   - Test with no camera available
   - Test with permission denied

2. **Image Capture**
   - Capture clear ID front
   - Capture clear ID back
   - Capture clear selfie

3. **Image Upload**
   - Upload to Cradle Voices server
   - Verify URL response
   - Handle upload failures

4. **KYC Submission**
   - Submit valid KYC data
   - Handle validation errors
   - Verify success response

## Troubleshooting

### Camera Not Initializing
- Ensure camera permission is granted
- Check device has camera available
- Verify camera package compatibility

### Upload Failures
- Check network connectivity
- Verify image file is valid
- Check Cradle Voices server status

### API Errors
- Verify endpoint URLs
- Check user ID validity
- Validate image URLs format

## Future Enhancements

- OCR for automatic ID data extraction
- Face recognition for liveness verification
- Document quality validation
- Retry mechanism for failed uploads
- Progress tracking for multi-image uploads
- Offline mode support
