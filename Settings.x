#import "YouTubePlus.h"

@interface YTSettingsSectionItemManager (YouTubePlus)
- (void)updateYouTubePlusSectionWithEntry:(id)entry;
@end

static const NSInteger YouTubePlusSection = 789;

static NSString *GetCacheSize() {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:cachePath error:nil];

    unsigned long long int folderSize = 0;
    for (NSString *fileName in filesArray) {
        NSString *filePath = [cachePath stringByAppendingPathComponent:fileName];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        folderSize += [fileAttributes fileSize];
    }

    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    formatter.countStyle = NSByteCountFormatterCountStyleFile;

    return [formatter stringFromByteCount:folderSize];
}

// Settings
%hook YTAppSettingsPresentationData
+ (NSArray *)settingsCategoryOrder {
    NSArray *order = %orig;
    NSMutableArray *mutableOrder = [order mutableCopy];
    NSUInteger insertIndex = [order indexOfObject:@(1)];
    if (insertIndex != NSNotFound)
        [mutableOrder insertObject:@(YouTubePlusSection) atIndex:insertIndex + 1];
    return mutableOrder;
}
%end

%hook YTSettingsGroupData
+ (NSMutableArray <NSNumber *> *)tweaks {
    Class groupClass = objc_getClass("YTSettingsGroupData");
    if (class_getClassMethod(groupClass, @selector(tweaks))) {
        NSMutableArray <NSNumber *> *tweaks = %orig;
        if (tweaks && ![tweaks containsObject:@(YouTubePlusSection)]) {
            [tweaks insertObject:@(YouTubePlusSection) atIndex:0];
        }
        return tweaks;
    }
    return [NSMutableArray arrayWithObject:@(YouTubePlusSection)];
}

- (NSArray <NSNumber *> *)orderedCategories {
    NSArray <NSNumber *> *categories = %orig;
    if (self.type == 1) {
        NSMutableArray *mutableCategories = categories.mutableCopy;
        if (![mutableCategories containsObject:@(YouTubePlusSection)]) {
            NSUInteger insertIndex = [mutableCategories indexOfObject:@(1)];
            if (insertIndex != NSNotFound)
                [mutableCategories insertObject:@(YouTubePlusSection) atIndex:insertIndex + 1];
            else
                [mutableCategories insertObject:@(YouTubePlusSection) atIndex:0];
        }
        return mutableCategories.copy;
    }
    return categories;
}

- (NSArray <NSNumber *> *)orderedCategoriesForGroupType:(NSUInteger)groupType {
    NSArray <NSNumber *> *categories = %orig;
    if (groupType == 1) {
        NSMutableArray *mutableCategories = categories.mutableCopy;
        if (![mutableCategories containsObject:@(YouTubePlusSection)]) {
            NSUInteger insertIndex = [mutableCategories indexOfObject:@(1)];
            if (insertIndex != NSNotFound)
                [mutableCategories insertObject:@(YouTubePlusSection) atIndex:insertIndex + 1];
            else
                [mutableCategories insertObject:@(YouTubePlusSection) atIndex:0];
        }
        return mutableCategories.copy;
    }
    return categories;
}
%end

%hook YTSettingsSectionController
- (void)setSelectedItem:(NSUInteger)selectedItem {
    if (selectedItem != NSNotFound) %orig;
}
%end

%hook YTSettingsCell
- (void)setIndicatorIcon:(int)icon {
    if ([self.accessibilityIdentifier isEqualToString:@"YouTubePlusSectionItem"]) {
        %orig(0);
        return;
    }
    %orig(icon);
}

- (void)setDetailText:(id)arg1 {
    if ([self.accessibilityIdentifier isEqualToString:@"YouTubePlusSectionItem"]) {
        if ([arg1 isKindOfClass:[NSString class]] && [arg1 isEqualToString:@"‣"]) {
            %orig(nil);
            return;
        }
    }
    %orig(arg1);
}

- (void)layoutSubviews {
    %orig;

    if ([self.accessibilityIdentifier isEqualToString:@"YouTubePlusSectionItem"]) {
        NSArray *indicatorKeys = @[@"_navigationChevronImageView", @"_navigationChevron", @"_indicatorImageView", @"_indicatorIcon"];
        for (NSString *key in indicatorKeys) {
            @try {
                UIView *view = [self valueForKey:key];
                if (view && [view isKindOfClass:[UIView class]]) {
                    view.hidden = YES;
                    view.alpha = 0.0;
                }
            } @catch (NSException *e) {}
        }
    }
}
%end

%hook YTSettingsSectionItemManager
%new
- (YTSettingsSectionItem *)switchWithTitle:(NSString *)title key:(NSString *)key {
    Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);
    Class YTAlertViewClass = %c(YTAlertView);
    NSString *titleDesc = [NSString stringWithFormat:@"%@Desc", title];

    YTSettingsSectionItem *item = [YTSettingsSectionItemClass switchItemWithTitle:LOC(title)
    titleDescription:LOC(titleDesc)
    accessibilityIdentifier:@"YouTubePlusSectionItem"
    switchOn:ytlBool(key)
    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
        if ([key isEqualToString:@"shortsOnlyMode"]) {
            YTAlertView *alertView = [YTAlertViewClass confirmationDialogWithAction:^{
                ytlSetBool(enabled, @"shortsOnlyMode");
            }
            actionTitle:LOC(@"Yes")
            cancelAction:^{
                [cell setSwitchOn:!enabled animated:YES];
            }
            cancelTitle:LOC(@"No")];
            alertView.title = LOC(@"Warning");
            alertView.subtitle = LOC(@"ShortsOnlyWarning");
            [alertView show];
        }

        else {
            ytlSetBool(enabled, key);

            NSArray *keys = @[@"removeLabels", @"removeIndicators", @"reExplore", @"addExplore", @"removeShorts", @"removeSubscriptions", @"removeUploads", @"removeLibrary"];
            if ([keys containsObject:key]) {
                [[[%c(YTHeaderContentComboViewController) alloc] init] refreshPivotBar];
            }
        }

        return YES;
    }
    settingItemId:0];

    return item;
}

%new
- (YTSettingsSectionItem *)linkWithTitle:(NSString *)title description:(NSString *)description link:(NSString *)link {
    return [%c(YTSettingsSectionItem) itemWithTitle:title
    titleDescription:description
    accessibilityIdentifier:@"YouTubePlusSectionItem"
    detailTextBlock:nil
    selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
        return [%c(YTUIUtils) openURL:[NSURL URLWithString:link]];
    }];
}

%new(v@:@)
- (void)updateYouTubePlusSectionWithEntry:(id)entry {
    NSMutableArray *sectionItems = [NSMutableArray array];
    Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);
    YTSettingsViewController *settingsViewController = nil;
    @try {
        settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];
    } @catch (NSException *e) {}
    if (!settingsViewController && [[self parentResponder] isKindOfClass:%c(YTSettingsViewController)]) {
        settingsViewController = (YTSettingsViewController *)[self parentResponder];
    }

    YTSettingsSectionItem *space = [%c(YTSettingsSectionItem) itemWithTitle:nil accessibilityIdentifier:@"YouTubePlusSectionItem" detailTextBlock:nil selectBlock:nil];

    YTSettingsSectionItem *general = [YTSettingsSectionItemClass itemWithTitle:LOC(@"General")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
            [self switchWithTitle:@"RemoveAds" key:@"noAds"],
            [self switchWithTitle:@"BackgroundPlayback" key:@"backgroundPlayback"]
        ];

        YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"General") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
        [settingsViewController pushViewController:picker];
        return YES;
    }];

    [sectionItems addObject:general];

    YTSettingsSectionItem *navbar = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Navbar")
    accessibilityIdentifier:@"YouTubePlusSectionItem"
    detailTextBlock:nil
    selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
        NSArray <YTSettingsSectionItem *> *rows = @[
            [self switchWithTitle:@"RemoveCast" key:@"noCast"],
            [self switchWithTitle:@"RemoveNotifications" key:@"noNotifsButton"],
            [self switchWithTitle:@"RemoveSearch" key:@"noSearchButton"],
            [self switchWithTitle:@"RemoveVoiceSearch" key:@"noVoiceSearchButton"]
        ];

        if (ytlBool(@"advancedMode")) {
            rows = [rows arrayByAddingObjectsFromArray:@[
                [self switchWithTitle:@"StickyNavbar" key:@"stickyNavbar"],
                [self switchWithTitle:@"NoSubbar" key:@"noSubbar"],
                [self switchWithTitle:@"NoYTLogo" key:@"noYTLogo"],
                [self switchWithTitle:@"PremiumYTLogo" key:@"premiumYTLogo"]
            ]];
        }

        YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Navbar") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
        [settingsViewController pushViewController:picker];
        return YES;
    }];

    [sectionItems addObject:navbar];

    if (ytlBool(@"advancedMode")) {
        YTSettingsSectionItem *overlay = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Overlay")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
                [self switchWithTitle:@"HideAutoplay" key:@"hideAutoplay"],
                [self switchWithTitle:@"HideSubs" key:@"hideSubs"],
                [self switchWithTitle:@"NoHUDMsgs" key:@"noHUDMsgs"],
                [self switchWithTitle:@"HidePrevNext" key:@"hidePrevNext"],
                [self switchWithTitle:@"ReplacePrevNext" key:@"replacePrevNext"],
                [self switchWithTitle:@"NoDarkBg" key:@"noDarkBg"],
                [self switchWithTitle:@"NoEndScreenCards" key:@"endScreenCards"],
                [self switchWithTitle:@"NoFullscreenActions" key:@"noFullscreenActions"],
                [self switchWithTitle:@"PersistentProgressBar" key:@"persistentProgressBar"],
                [self switchWithTitle:@"StockVolumeHUD" key:@"stockVolumeHUD"],
                [self switchWithTitle:@"NoRelatedVids" key:@"noRelatedVids"],
                [self switchWithTitle:@"NoPromotionCards" key:@"noPromotionCards"],
                [self switchWithTitle:@"NoWatermarks" key:@"noWatermarks"],
                [self switchWithTitle:@"VideoEndTime" key:@"videoEndTime"],
                [self switchWithTitle:@"24hrFormat" key:@"24hrFormat"]
            ];

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Overlay") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:overlay];

        YTSettingsSectionItem *player = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Player")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
                [self switchWithTitle:@"Miniplayer" key:@"miniplayer"],
                [self switchWithTitle:@"PortraitFullscreen" key:@"portraitFullscreen"],
                [self switchWithTitle:@"CopyWithTimestamp" key:@"copyWithTimestamp"],
                [self switchWithTitle:@"DisableAutoplay" key:@"disableAutoplay"],
                [self switchWithTitle:@"DisableAutoCaptions" key:@"disableAutoCaptions"],
                [self switchWithTitle:@"NoContentWarning" key:@"noContentWarning"],
                [self switchWithTitle:@"ClassicQuality" key:@"classicQuality"],
                [self switchWithTitle:@"ExtraSpeedOptions" key:@"extraSpeedOptions"],
                [self switchWithTitle:@"DontSnap2Chapter" key:@"dontSnapToChapter"],
                [self switchWithTitle:@"NoTwoFingerSnapToChapter" key:@"noTwoFingerSnapToChapter"],
                [self switchWithTitle:@"PauseOnOverlay" key:@"pauseOnOverlay"],
                [self switchWithTitle:@"RedProgressBar" key:@"redProgressBar"],
                [self switchWithTitle:@"NoPlayerRemixButton" key:@"noPlayerRemixButton"],
                [self switchWithTitle:@"NoPlayerClipButton" key:@"noPlayerClipButton"],
                [self switchWithTitle:@"NoPlayerDownloadButton" key:@"noPlayerDownloadButton"],
                [self switchWithTitle:@"NoHints" key:@"noHints"],
                [self switchWithTitle:@"NoFreeZoom" key:@"noFreeZoom"],
                [self switchWithTitle:@"AutoFullscreen" key:@"autoFullscreen"],
                [self switchWithTitle:@"ExitFullscreen" key:@"exitFullscreen"],
                [self switchWithTitle:@"NoDoubleTap2Seek" key:@"noDoubleTapToSeek"]
            ];

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Player") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:player];

        YTSettingsSectionItem *shorts = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Shorts")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
                [self switchWithTitle:@"ShortsOnlyMode" key:@"shortsOnlyMode"],
                [self switchWithTitle:@"AutoSkipShorts" key:@"autoSkipShorts"],
                [self switchWithTitle:@"HideShorts" key:@"hideShorts"],
                [self switchWithTitle:@"ShortsProgress" key:@"shortsProgress"],
                [self switchWithTitle:@"PinchToFullscreenShorts" key:@"pinchToFullscreenShorts"],
                [self switchWithTitle:@"ShortsToRegular" key:@"shortsToRegular"],
                [self switchWithTitle:@"ResumeShorts" key:@"resumeShorts"],
                [self switchWithTitle:@"HideShortsLogo" key:@"hideShortsLogo"],
                [self switchWithTitle:@"HideShortsSearch" key:@"hideShortsSearch"],
                [self switchWithTitle:@"HideShortsCamera" key:@"hideShortsCamera"],
                [self switchWithTitle:@"HideShortsMore" key:@"hideShortsMore"],
                [self switchWithTitle:@"HideShortsSubscriptions" key:@"hideShortsSubscriptions"],
                [self switchWithTitle:@"HideShortsLike" key:@"hideShortsLike"],
                [self switchWithTitle:@"HideShortsDislike" key:@"hideShortsDislike"],
                [self switchWithTitle:@"HideShortsComments" key:@"hideShortsComments"],
                [self switchWithTitle:@"HideShortsRemix" key:@"hideShortsRemix"],
                [self switchWithTitle:@"HideShortsShare" key:@"hideShortsShare"],
                [self switchWithTitle:@"HideShortsAvatars" key:@"hideShortsAvatars"],
                [self switchWithTitle:@"HideShortsThanks" key:@"hideShortsThanks"],
                [self switchWithTitle:@"HideShortsSource" key:@"hideShortsSource"],
                [self switchWithTitle:@"HideShortsChannelName" key:@"hideShortsChannelName"],
                [self switchWithTitle:@"HideShortsDescription" key:@"hideShortsDescription"],
                [self switchWithTitle:@"HideShortsAudioTrack" key:@"hideShortsAudioTrack"],
                [self switchWithTitle:@"NoPromotionCards" key:@"hideShortsPromoCards"]
            ];

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Shorts") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:shorts];
    }

    YTSettingsSectionItem *tabbar = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Tabbar")
    accessibilityIdentifier:@"YouTubePlusSectionItem"
    detailTextBlock:nil
    selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
        NSArray <YTSettingsSectionItem *> *rows = @[
            [self switchWithTitle:@"RemoveLabels" key:@"removeLabels"],
            [self switchWithTitle:@"RemoveIndicators" key:@"removeIndicators"],
            [self switchWithTitle:@"ReExplore" key:@"reExplore"],
            [self switchWithTitle:@"AddExplore" key:@"addExplore"],
            [self switchWithTitle:@"HideShortsTab" key:@"removeShorts"],
            [self switchWithTitle:@"HideSubscriptionsTab" key:@"removeSubscriptions"],
            [self switchWithTitle:@"HideUploadButton" key:@"removeUploads"],
            [self switchWithTitle:@"HideLibraryTab" key:@"removeLibrary"]
        ];

        YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Tabbar") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
        [settingsViewController pushViewController:picker];
        return YES;
    }];

    [sectionItems addObject:tabbar];

    if (ytlBool(@"advancedMode")) {
        YTSettingsSectionItem *other = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Other")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
                [self switchWithTitle:@"CopyVideoInfo" key:@"copyVideoInfo"],
                [self switchWithTitle:@"PostManager" key:@"postManager"],
                [self switchWithTitle:@"SaveProfilePhoto" key:@"saveProfilePhoto"],
                [self switchWithTitle:@"CommentManager" key:@"commentManager"],
                [self switchWithTitle:@"FixAlbums" key:@"fixAlbums"],
                [self switchWithTitle:@"NativeShare" key:@"nativeShare"],
                [self switchWithTitle:@"RemovePlayNext" key:@"removePlayNext"],
                [self switchWithTitle:@"RemoveDownloadMenu" key:@"removeDownloadMenu"],
                [self switchWithTitle:@"RemoveWatchLaterMenu" key:@"removeWatchLaterMenu"],
                [self switchWithTitle:@"RemoveSaveToPlaylistMenu" key:@"removeSaveToPlaylistMenu"],
                [self switchWithTitle:@"RemoveShareMenu" key:@"removeShareMenu"],
                [self switchWithTitle:@"RemoveNotInterestedMenu" key:@"removeNotInterestedMenu"],
                [self switchWithTitle:@"RemoveDontRecommendMenu" key:@"removeDontRecommendMenu"],
                [self switchWithTitle:@"RemoveReportMenu" key:@"removeReportMenu"],
                [self switchWithTitle:@"NoContinueWatching" key:@"noContinueWatching"],
                [self switchWithTitle:@"NoSearchHistory" key:@"noSearchHistory"],
                [self switchWithTitle:@"NoRelatedWatchNexts" key:@"noRelatedWatchNexts"],
                [self switchWithTitle:@"StickSortComments" key:@"stickSortComments"],
                [self switchWithTitle:@"HideSortComments" key:@"hideSortComments"],
                [self switchWithTitle:@"PlaylistOldMinibar" key:@"playlistOldMinibar"],
                [self switchWithTitle:@"DisableRTL" key:@"disableRTL"]
            ];

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Other") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:other];

        [sectionItems addObject:space];

        YTSettingsSectionItem *speed = [YTSettingsSectionItemClass itemWithTitle:LOC(@"HoldToSpeed")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:^NSString *() {
            NSArray *speedLabels = @[LOC(@"Disabled"), LOC(@"Default"), @"0.25×", @"0.5×", @"0.75×", @"1.0×", @"1.25×", @"1.5×", @"1.75×", @"2.0×", @"3.0×", @"4.0×", @"5.0×"];
            return speedLabels[ytlInt(@"speedIndex")];
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSMutableArray <YTSettingsSectionItem *> *rows = [NSMutableArray array];
            NSArray *speedLabels = @[LOC(@"Disable"), LOC(@"Default"), @"0.25×", @"0.5×", @"0.75×", @"1.0×", @"1.25×", @"1.5×", @"1.75×", @"2.0×", @"3.0×", @"4.0×", @"5.0×"];

            for (NSUInteger i = 0; i < speedLabels.count; i++) {
                NSString *title = speedLabels[i];
                YTSettingsSectionItem *item = [YTSettingsSectionItemClass checkmarkItemWithTitle:title titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [settingsViewController reloadData];
                    ytlSetInt((int)arg1, @"speedIndex");
                    return YES;
                }];

                [rows addObject:item];
            }

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"HoldToSpeed") pickerSectionTitle:nil rows:rows selectedItemIndex:ytlInt(@"speedIndex") parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:speed];

        YTSettingsSectionItem *autoSpeed = [YTSettingsSectionItemClass itemWithTitle:LOC(@"DefaultPlaybackRate")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:^NSString *() {
            NSArray *speedLabels = @[@"0.25×", @"0.5×", @"0.75×", @"1.0×", @"1.25×", @"1.5×", @"1.75×", @"2.0×", @"3.0×", @"4.0×", @"5.0×"];
            return speedLabels[ytlInt(@"autoSpeedIndex")];
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSMutableArray <YTSettingsSectionItem *> *rows = [NSMutableArray array];
            NSArray *speedLabels = @[@"0.25×", @"0.5×", @"0.75×", @"1.0×", @"1.25×", @"1.5×", @"1.75×", @"2.0×", @"3.0×", @"4.0×", @"5.0×"];

            for (NSUInteger i = 0; i < speedLabels.count; i++) {
                NSString *title = speedLabels[i];
                YTSettingsSectionItem *item = [YTSettingsSectionItemClass checkmarkItemWithTitle:title titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [settingsViewController reloadData];
                    ytlSetInt((int)arg1, @"autoSpeedIndex");
                    return YES;
                }];
                [rows addObject:item];
            }

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"DefaultPlaybackRate") pickerSectionTitle:nil rows:rows selectedItemIndex:ytlInt(@"autoSpeedIndex") parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:autoSpeed];

        YTSettingsSectionItem *wifiQuality = [YTSettingsSectionItemClass itemWithTitle:LOC(@"PlaybackQualityOnWiFi")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:^NSString *() {
            NSArray *qualityLabels = @[LOC(@"Default"), LOC(@"Best"), @"2160p60", @"2160p", @"1440p60", @"1440p", @"1080p60", @"1080p", @"720p60", @"720p", @"480p", @"360p"];
            return qualityLabels[ytlInt(@"wiFiQualityIndex")];
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSMutableArray <YTSettingsSectionItem *> *rows = [NSMutableArray array];
            NSArray *qualityLabels = @[LOC(@"Default"), LOC(@"Best"), @"2160p60", @"2160p", @"1440p60", @"1440p", @"1080p60", @"1080p", @"720p60", @"720p", @"480p", @"360p"];

            for (NSUInteger i = 0; i < qualityLabels.count; i++) {
                NSString *title = qualityLabels[i];
                YTSettingsSectionItem *item = [YTSettingsSectionItemClass checkmarkItemWithTitle:title titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [settingsViewController reloadData];
                    ytlSetInt((int)arg1, @"wiFiQualityIndex");
                    return YES;
                }];

                [rows addObject:item];
            }

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"SelectQuality") pickerSectionTitle:nil rows:rows selectedItemIndex:ytlInt(@"wiFiQualityIndex") parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:wifiQuality];

        YTSettingsSectionItem *cellQuality = [YTSettingsSectionItemClass itemWithTitle:LOC(@"PlaybackQualityOnCellular")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:^NSString *() {
            NSArray *qualityLabels = @[LOC(@"Default"), LOC(@"Best"), @"2160p60", @"2160p", @"1440p60", @"1440p", @"1080p60", @"1080p", @"720p60", @"720p", @"480p", @"360p"];
            return qualityLabels[ytlInt(@"cellQualityIndex")];
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSMutableArray <YTSettingsSectionItem *> *rows = [NSMutableArray array];
            NSArray *qualityLabels = @[LOC(@"Default"), LOC(@"Best"), @"2160p60", @"2160p", @"1440p60", @"1440p", @"1080p60", @"1080p", @"720p60", @"720p", @"480p", @"360p"];

            for (NSUInteger i = 0; i < qualityLabels.count; i++) {
                NSString *title = qualityLabels[i];
                YTSettingsSectionItem *item = [YTSettingsSectionItemClass checkmarkItemWithTitle:title titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [settingsViewController reloadData];
                    ytlSetInt((int)arg1, @"cellQualityIndex");
                    return YES;
                }];

                [rows addObject:item];
            }

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"SelectQuality") pickerSectionTitle:nil rows:rows selectedItemIndex:ytlInt(@"cellQualityIndex") parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:cellQuality];

        YTSettingsSectionItem *startup = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Startup")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:^NSString *() {
            NSArray *tabLabels = @[LOC(@"Home"), LOC(@"Explore"), LOC(@"ShortsTab"), LOC(@"Subscriptions"), LOC(@"Library")];
            return tabLabels[ytlInt(@"pivotIndex")];
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSMutableArray <YTSettingsSectionItem *> *rows = [NSMutableArray array];
            NSArray *tabLabels = @[LOC(@"Home"), LOC(@"Explore"), LOC(@"ShortsTab"), LOC(@"Subscriptions"), LOC(@"Library")];

            for (NSUInteger i = 0; i < tabLabels.count; i++) {
                NSString *title = tabLabels[i];
                YTSettingsSectionItem *item = [YTSettingsSectionItemClass checkmarkItemWithTitle:title titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    if (([title isEqualToString:LOC(@"Explore")] && !ytlBool(@"reExplore") && !ytlBool(@"addExplore")) ||
                        ([title isEqualToString:LOC(@"ShortsTab")] && ytlBool(@"removeShorts")) ||
                        ([title isEqualToString:LOC(@"Subscriptions")] && ytlBool(@"removeSubscriptions")) ||
                        ([title isEqualToString:LOC(@"Library")] && ytlBool(@"removeLibrary"))) {
                            YTAlertView *alertView = [%c(YTAlertView) infoDialog];
                            alertView.title = LOC(@"Warning");
                            alertView.subtitle = LOC(@"TabIsHidden");
                            [alertView show];
                            return NO;
                    } else {
                        [settingsViewController reloadData];
                        ytlSetInt((int)arg1, @"pivotIndex");
                        return YES;
                    }
                }];

                [rows addObject:item];
            }

            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"Startup") pickerSectionTitle:nil rows:rows selectedItemIndex:ytlInt(@"pivotIndex") parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

        [sectionItems addObject:startup];
    }
    
    [sectionItems addObject:space];

    YTSettingsSectionItem *version = [YTSettingsSectionItemClass itemWithTitle:LOC(@"Version")
        accessibilityIdentifier:@"YouTubePlusSectionItem"
        detailTextBlock:^NSString *() {
            return @(OS_STRINGIFY(TWEAK_VERSION));
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
                [self switchWithTitle:@"Advanced" key:@"advancedMode"],

                [%c(YTSettingsSectionItem) itemWithTitle:LOC(@"ClearCache") titleDescription:nil accessibilityIdentifier:@"YouTubePlusSectionItem" detailTextBlock:^NSString *() { return GetCacheSize(); } selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
                        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
                    });

                    [[%c(YTToastResponderEvent) eventWithMessage:LOC(@"Done") firstResponder:[self parentResponder]] send];

                    return YES;
                }],

                [%c(YTSettingsSectionItem) itemWithTitle:LOC(@"ResetSettings") titleDescription:nil accessibilityIdentifier:@"YouTubePlusSectionItem" detailTextBlock:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
                        [YTLUserDefaults resetUserDefaults];

                        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
                        [NSThread sleepForTimeInterval:1.0];
                        exit(0);
                    }
                    actionTitle:LOC(@"Yes")
                    cancelTitle:LOC(@"No")];
                    alertView.title = LOC(@"Warning");
                    alertView.subtitle = LOC(@"ResetMessage");
                    [alertView show];

                    return YES;
                }]
            ];

        YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:LOC(@"About") pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:[self parentResponder]];
        [settingsViewController pushViewController:picker];
        return YES;
    }];

    [sectionItems addObject:version];

    BOOL isNew = [settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)];
    isNew ? [settingsViewController setSectionItems:sectionItems forCategory:YouTubePlusSection title:@"YouTube Plus" icon:nil titleDescription:nil headerHidden:NO]
          : [settingsViewController setSectionItems:sectionItems forCategory:YouTubePlusSection title:@"YouTube Plus" titleDescription:nil headerHidden:NO];

}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == YouTubePlusSection) {
        [self updateYouTubePlusSectionWithEntry:entry];
        return;
    } %orig;
}
%end
