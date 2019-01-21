#import <CSWeatherStore.h>
#import <PrivateHeaders.h>

#define localCoder @"/var/mobile/Library/Preferences/com.creaturecoding.local.coder"
#define defaultCoder @"/var/mobile/Library/Preferences/com.creaturecoding.default.coder"
#define MIN_UPDATE_INTERVAL 900

typedef NSDictionary<NSString *, NSString *> *ConditionTable;
enum {
	ConditionImageTypeDefault = 0,
	ConditionImageTypeDay = 1,
	ConditionImageTypeNight = 2
};
typedef NSUInteger ConditionImageType;

@interface CSWeatherStore ()
@property (nonatomic, retain, readonly) NSMutableDictionary *metadata;
@end

@implementation CSWeatherStore {
	NSMutableDictionary *_metadata;
	BOOL _isLocalWeather;
	WeatherPreferences *_weatherPreferences;
	WATodayAutoupdatingLocationModel *_todayModel;
	ConditionTable _conditionsTable;
	NSBundle *_weatherBundle;
	NSBundle *_bundle;
	NSTimer *_timer;
}

#pragma mark type methods

+ (CSWeatherStore *)weatherStoreForLocalWeather:(BOOL)local {
	CSWeatherStore *store = [[CSWeatherStore alloc] initForLocalWeather:local];
	return store;
}

+ (CSWeatherStore *)weatherStoreForLocalWeather:(BOOL)local updateHandler:(CSWUpdateHandler)handler {
	CSWeatherStore *store = [[CSWeatherStore alloc] initForLocalWeather:local updateHandler:handler];
	return store;
}

+ (CSWeatherStore *)weatherStoreForLocalWeather:(BOOL)local autoUpdateInterval:(NSInteger)interval savedCityIndex:(NSInteger)index updateHandler:(CSWUpdateHandler)handler {
	CSWeatherStore *store = [[CSWeatherStore alloc] initForLocalWeather:local autoUpdateInterval:interval savedCityIndex:index updateHandler:handler];
	return store;
}

#pragma mark init

- (instancetype)init {
	if ((self = [super init])) {
		_metadata = [NSMutableDictionary new];
	}
	
	return self;
}

- (instancetype)initForLocalWeather:(BOOL)local {
	if ((self = [super init])) {
		_isLocalWeather = local;
		self.handler = nil;
		self.autoUpdateInterval = -1;
		self.savedCityIndex = 0;
		
		[self load];
		
		if ([self isExpired]) {
			[self update];
		}
	}
	
	return self;
}

- (instancetype)initForLocalWeather:(BOOL)local updateHandler:(CSWUpdateHandler)handler {
	if ((self = [super init])) {
		_isLocalWeather = local;
		self.handler = handler;
		self.autoUpdateInterval = -1;
		self.savedCityIndex = 0;
		
		[self load];
		
		if ([self isExpired]) {
			[self update];
		}
	}
	
	return self;
}

- (instancetype)initForLocalWeather:(BOOL)local autoUpdateInterval:(NSInteger)interval savedCityIndex:(NSInteger)index updateHandler:(CSWUpdateHandler)handler {
	if ((self = [super init])) {
		_isLocalWeather = local;
		self.handler = handler;
		self.autoUpdateInterval = interval;
		self.savedCityIndex = index;
		
		[self load];
		
		if ([self isExpired]) {
			[self update];
		}
	}
	
	return self;
}

#pragma mark key value

- (void)setValue:(id)value forKeyPath:(NSString *)key {
	if (!_metadata)
		_metadata = [NSMutableDictionary new];
		
	if (value && key)
		[_metadata setValue:value forKey:key];
}

- (id)objectForKey:(NSString *)key {
	return self.metadata[key];
}

#pragma mark private

- (NSMutableDictionary *)metadata {
	if (!_metadata)
		_metadata = [NSMutableDictionary new];
		
	return _metadata;
}

- (BOOL)isExpired {
	return !self.metadata || !self.metadata[@"last_update"] || [[NSDate date] timeIntervalSince1970] - [self lastUpdated] > 300;
}

#pragma mark NSCoding

- (NSString *)coderPath {
	return [self isLocalWeather] ? localCoder : defaultCoder;
}

- (void)save {
	[NSKeyedArchiver archiveRootObject:_metadata toFile:[self coderPath]];
}

- (BOOL)load {
	NSData *archive;
	
	@try {
		archive = [NSKeyedUnarchiver unarchiveObjectWithFile:[self coderPath]];
		_metadata = [archive isKindOfClass:NSDictionary.class] ? (NSMutableDictionary *)archive : nil;
	} 
	
	@catch (NSException *exception) {
		_metadata = nil;
	}
	
	return _metadata != nil;
}

#pragma mark property implementation

- (NSString *)currentCityName {
	return self.metadata[@"city"];
}

- (NSString *)currentConditionDescription {
	return self.metadata[@"description"];
}

- (UIImage *)currentConditionImageLarge {
	return self.metadata[@"image_large"];
}

- (UIImage *)currentConditionImageSmall {
	return self.metadata[@"image_small"];
}

- (UIImage *)currentConditionImageDark {
	return self.metadata[@"image_dark"];
}

- (NSString *)currentConditionOverview {
	return self.metadata[@"overview"];
}

- (NSString *)currentTemperatureFahrenheit {
	return self.metadata[@"current_temp_fah"];
}

- (NSString *)currentTemperatureCelsius {
	return self.metadata[@"current_temp_cel"];
}

- (NSString *)currentTemperatureLocale {
	return self.metadata[@"current_temp_loc"];
}

- (NSString *)predictedHighTemperatureFahrenheit {
	return self.metadata[@"high_temp_fah"];
}

- (NSString *)predictedHighTemperatureCelsius {
	return self.metadata[@"high_temp_cel"];
}

- (NSString *)predictedHighTemperatureLocale {
	return self.metadata[@"high_temp_loc"];
}

- (NSString *)predictedLowTemperatureFahrenheit {
	return self.metadata[@"low_temp_fah"];
}

- (NSString *)predictedLowTemperatureCelsius {
	return self.metadata[@"low_temp_cel"];
}

- (NSString *)predictedLowTemperatureLocale {
	return self.metadata[@"low_temp_loc"];
}

- (NSString *)currentFeelsLikeTemperatureFahrenheit {
	return self.metadata[@"feels_like_fah"];
}

- (NSString *)currentFeelsLikeTemperatureCelsius {
	return self.metadata[@"feels_like_cel"];
}

- (NSString *)currentFeelsLikeTemperatureLocale {
	return self.metadata[@"feels_like_loc"];
}

- (NSInteger)lastUpdated {
	return [self.metadata[@"last_update"] integerValue];
}

- (void)setAutoUpdateInterval:(NSInteger)interval {
	if (interval == _autoUpdateInterval) return;
	
	if (interval == -1 && _timer) {
		[_timer invalidate];
	}
	
	else if (interval * 60 < MIN_UPDATE_INTERVAL) {
		interval = MIN_UPDATE_INTERVAL / 60;
	}
	
	_autoUpdateInterval = interval;
	
	if (interval != -1) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:interval * 60 repeats:YES block:^(NSTimer *timer) {
			[self update];
		}];
	}
}

- (void)setSavedCityIndex:(NSInteger)index {
	if (_savedCityIndex != index)
		_savedCityIndex = [[self weatherPreferences] loadSavedCities].count >= index ? index : 0;
}

#pragma mark update

- (void)update {
	@synchronized(self) {
		__block City *currentCity = [self fetchCity];
	
		void (^handler)() = ^{ [self updateWithCity:currentCity]; };

		if ([self isLocalWeather]) {
			if ([[TWCLocationUpdater sharedLocationUpdater] respondsToSelector:@selector(updateWeatherForLocation:city:isFromFrameworkClient:withCompletionHandler:)]) {
				[[TWCLocationUpdater sharedLocationUpdater] updateWeatherForLocation:[self todayModel].locationManager.location city:currentCity isFromFrameworkClient:NO withCompletionHandler:handler];
			} else {
				[[TWCLocationUpdater sharedLocationUpdater] updateWeatherForLocation:[self todayModel].locationManager.location city:currentCity withCompletionHandler:handler];
			}
		}

		else {
			[[TWCCityUpdater sharedCityUpdater] updateWeatherForCities:@[currentCity] withCompletionHandler:handler];
		}
	}
}

#pragma mark update internal

- (NSBundle *)bundle {
	if (!_bundle) {
		_bundle = [NSBundle bundleForClass:self.class];
	}
	
	return _bundle;
}

- (NSBundle *)weatherBundle {
	if (!_weatherBundle) {
		_weatherBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Weather.framework"];
		[_weatherBundle load];
	}
	
	return _weatherBundle;
}

- (ConditionTable)conditionsTable {
	if (!_conditionsTable) {
		_conditionsTable = [NSDictionary dictionaryWithContentsOfFile:[[self bundle] pathForResource:@"ConditionKeys" ofType:@"plist"]];
	}
	
	return _conditionsTable;
}

- (WeatherPreferences *)weatherPreferences {
	if (!_weatherPreferences) {
		_weatherPreferences = [NSClassFromString(@"WeatherPreferences") sharedPreferences];
	}
	
	return _weatherPreferences;
}

- (WATodayAutoupdatingLocationModel *)todayModel {
	if (!_todayModel) {
		_todayModel = [NSClassFromString(@"WATodayModel") autoupdatingLocationModelWithPreferences:[self weatherPreferences] effectiveBundleIdentifier:@"com.apple.weather"];
	}
	
	return _todayModel;
}

- (BOOL)locationServicesEnabled {
	return [[CLLocationManager sharedManager] locationServicesEnabled];
}

- (City *)fetchCity {
	__block City *currentCity;
	
	void (^local)() = ^ {currentCity = [self weatherPreferences].isLocalWeatherEnabled ? [self weatherPreferences].localWeatherCity : nil; };
	void (^location)() = ^{ currentCity = [self todayModel].forecastModel.city; };
	void (^saved)() = ^{NSArray <City *> *cities = [[self weatherPreferences] loadSavedCities]; currentCity =  cities.count ? cities.count >= self.savedCityIndex ? cities[self.savedCityIndex] : cities[0] : [[self weatherPreferences] _defaultCities][0]; };
	
	[self isLocalWeather] ? [self locationServicesEnabled] ? location() : local() : saved();
	
	if (!currentCity)
		saved();
		
	return currentCity;
}

- (BOOL)isCelsius {
	return [[self weatherPreferences] isCelsius];
}

- (NSString *)localizedStringForKey:(NSString *)key {
	return [[self weatherBundle] localizedStringForKey:key value:key table:@"WeatherFrameworkLocalizableStrings"];
}

- (UIImage *)imageForKey:(NSString *)key {
	return [UIImage imageNamed:key inBundle:[self weatherBundle] compatibleWithTraitCollection:nil];
}

- (NSString *)conditionStringForConditionCode:(NSInteger)conditionCode {
	return [self localizedStringForKey:[self conditionsTable][@(conditionCode).stringValue]];
}

- (void)updateWithCity:(City *)city {
	@autoreleasepool {
		
		NSInteger conditionCode = 		[city conditionCode];
		WFTemperature *temperature = 	[city temperature];
		WFTemperature *feelsLike = 		[city feelsLike];
		WFTemperature *high = 			[[city.dayForecasts firstObject] high];
		WFTemperature *low = 			[[city.dayForecasts firstObject] low];

		NSString *conditionImageName = 	[WeatherImageLoader conditionImageNameWithConditionIndex:conditionCode];

		@try {

			ConditionImageType type = 	[conditionImageName containsString:@"day"] ? ConditionImageTypeDay : [conditionImageName containsString:@"night"] ? ConditionImageTypeNight : ConditionImageTypeDefault;
			NSString *rootName;

			switch (type) {
				case ConditionImageTypeDefault: {
					[self setValue:[self imageForKey:[conditionImageName stringByAppendingString:@"-nc"]]
						   forKeyPath:@"image_large"];

					[self setValue:[self imageForKey:[conditionImageName stringByAppendingString:@"-white"]]
						   forKeyPath:@"image_small"];

					[self setValue:[self imageForKey:[conditionImageName stringByAppendingString:@"-black"]]
						   forKeyPath:@"image_dark"];
				} break;

				case ConditionImageTypeDay: {
					rootName = [[conditionImageName stringByReplacingOccurrencesOfString:@"-day" withString:@""] stringByReplacingOccurrencesOfString:@"_day" withString:@""];

					[self setValue:[self imageForKey:[rootName stringByAppendingString:@"_day-nc"]] ? :
					[self imageForKey:[rootName stringByAppendingString:@"-day-nc"]]
						   forKeyPath:@"image_large"];

					[self setValue:[self imageForKey:[rootName stringByAppendingString:@"_day-white"]] ? :
					[self imageForKey:[rootName stringByAppendingString:@"-day-white"]]
						   forKeyPath:@"image_small"];

					[self setValue:[self imageForKey:[rootName stringByAppendingString:@"_day-black"]] ? :
					[self imageForKey:[rootName stringByAppendingString:@"-day-black"]]
						   forKeyPath:@"image_dark"];
				} break;

				case ConditionImageTypeNight: {
					rootName = [[conditionImageName stringByReplacingOccurrencesOfString:@"-night" withString:@""] stringByReplacingOccurrencesOfString:@"_night" withString:@""];

					[self setValue:[self imageForKey:[rootName stringByAppendingString:@"_night-nc"]] ? :
					[self imageForKey:[rootName stringByAppendingString:@"-night-nc"]]
						   forKeyPath:@"image_large"];

					[self setValue:[self imageForKey:[rootName stringByAppendingString:@"_night-white"]] ? :
					[self imageForKey:[rootName stringByAppendingString:@"-night-white"]]
						   forKeyPath:@"image_small"];

					[self setValue:[self imageForKey:[rootName stringByAppendingString:@"_night-black"]] ? :
					[self imageForKey:[rootName stringByAppendingString:@"-night-black"]]
						   forKeyPath:@"image_dark"];
				} break;
			}
		} @catch (NSException *e) {}

		[self setValue:[city name] 													forKeyPath:@"city"];
		[self setValue:[city naturalLanguageDescription] 								forKeyPath:@"overview"];
		[self setValue:[self conditionStringForConditionCode:conditionCode] 			forKeyPath:@"description"];

		[self setValue:[NSString stringWithFormat:@"%.0f°", temperature.fahrenheit] 	forKeyPath:@"current_temp_fah"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", temperature.celsius] 		forKeyPath:@"current_temp_cel"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", high.fahrenheit] 			forKeyPath:@"high_temp_fah"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", high.celsius] 				forKeyPath:@"high_temp_cel"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", low.fahrenheit] 			forKeyPath:@"low_temp_fah"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", low.celsius] 				forKeyPath:@"low_temp_cel"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", feelsLike.fahrenheit] 		forKeyPath:@"feels_like_fah"];
		[self setValue:[NSString stringWithFormat:@"%.0f°", feelsLike.celsius] 		forKeyPath:@"feels_like_cel"];

		[self setValue:@([[NSDate date] timeIntervalSince1970]) 						forKeyPath:@"last_update"];

		[self setValue:[self isCelsius] ? [self objectForKey:@"low_temp_cel"] : [self objectForKey:@"low_temp_fah"] 			forKeyPath:@"low_temp_loc"];
		[self setValue:[self isCelsius] ? [self objectForKey:@"high_temp_cel"] : [self objectForKey:@"high_temp_fah"] 		forKeyPath:@"high_temp_loc"];
		[self setValue:[self isCelsius] ? [self objectForKey:@"current_temp_cel"] : [self objectForKey:@"current_temp_fah"] 	forKeyPath:@"current_temp_loc"];
		[self setValue:[self isCelsius] ? [self objectForKey:@"feels_like_cel"] : [self objectForKey:@"feels_like_fah"] 		forKeyPath:@"feels_like_loc"];
		
		if (self.handler) self.handler(self);
		
		[self save];
	}
}

@end