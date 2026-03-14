# Plan: Improve Donor Dashboard - Can Donate View

## Current Issues
1. Receiver cards (UserCard) are too big - need to be smaller
2. DonorHeader is a big gradient container - should become AppBar when showing list
3. Need better overall design for "can donate" state

## Changes Required

### 1. Convert Header to AppBar Style
**File**: `donor_dashboard_screen.dart`

When donor can donate (not deferred):
- Remove the gradient header card
- Use SliverAppBar with gradient background
- Show blood type, points, receiver count in AppBar
- Collapsible AppBar that blends with background

### 2. Create Smaller Receiver Card
**New File**: `receiver_card.dart` in widgets folder

Create a compact receiver card:
- Smaller padding: 12px (vs 18px)
- Smaller blood type circle: 48px (vs 68px)
- Remove pulsing ring animation (too heavy)
- Smaller fonts: 15px title, 13px subtitle (vs 17px/15px)
- Simpler layout: Row with avatar, content, call button
- Height: ~80px per card (vs current ~120px)

### 3. Update ReceiverList
**File**: `receiver_list.dart`

- Use new compact ReceiverCard
- Tighter spacing: 8px between cards (vs 16px)
- Better padding: 16px horizontal
- Remove old UserCard dependency

### 4. Redesign Dashboard Layout
**File**: `donor_dashboard_screen.dart`

When NOT deferred:
```
CustomScrollView(
  slivers: [
    SliverAppBar(
      expandedHeight: 120,
      flexibleSpace: GradientHeader(
        bloodType, points, count
      ),
    ),
    SliverToBoxAdapter(
      child: ReceiverList(
        compact: true,
        cards: [...]
      ),
    ),
  ],
)
```

### 5. UI Design Principles (from Flutter UI Skill)
- **Spacing**: 8px grid - 12-16px padding, 8-12px gaps
- **Typography**: Max 3 sizes - 15px title, 13px body, 12px caption
- **Cards**: 12px radius, minimal shadow (0.05 opacity)
- **No heavy animations**: Remove pulsing rings
- **Clean hierarchy**: Avatar → Content → Action

## File Structure
```
lib/features/donor/dashboard/presentation/widgets/
├── deferral_view.dart (already perfect)
├── donor_header.dart (modify for AppBar use)
├── receiver_list.dart (use compact cards)
└── receiver_card.dart (NEW - compact card)
```

## Testing Checklist
- [ ] AppBar blends with background (no shadow)
- [ ] Cards are compact (~80px height)
- [ ] Can see 4-5 cards on screen without scroll
- [ ] Call button easily tappable (44px min)
- [ ] Blood type badge visible but not oversized
- [ ] Works in both light and dark mode
