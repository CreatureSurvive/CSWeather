@interface CSWeatherStore : NSObject {
	
}

typedef void (^CSWUpdateHandler)(CSWeatherStore *);

//
// update handler
// code block to be run once a weather update cycle is complete
// ie: `handler = ^(CSWeatherStore *store) { /* code here */ };
@property (nonatomic, copy)CSWUpdateHandler handler;

//
// interval in minutes that the weather store should update
// the minimum value is 15, lower values will be set to the minimum
// if the value is set to -1, auto update will be disabled
// if a handler is set on this instance, the handler will be triggered after the update
@property (nonatomic, assign) NSInteger autoUpdateInterval;

//
// current city name
//
@property (nonatomic, retain, readonly) NSString *currentCityName;

//
// current condition description (sunny | cloudy | rainy | etc)
//
@property (nonatomic, retain, readonly) NSString *currentConditionDescription;

//
// current condition image assets
//
@property (nonatomic, retain, readonly) UIImage *currentConditionImageLarge;
@property (nonatomic, retain, readonly) UIImage *currentConditionImageSmall;
@property (nonatomic, retain, readonly) UIImage *currentConditionImageDark;

//
// current condition description in localized natural language
//
@property (nonatomic, retain, readonly) NSString *currentConditionOverview;

//
// current condition temperatures
//
@property (nonatomic, retain, readonly) NSString *currentTemperatureFahrenheit;
@property (nonatomic, retain, readonly) NSString *currentTemperatureCelsius;
@property (nonatomic, retain, readonly) NSString *currentTemperatureLocale;

//
// predicted high temperatures
//
@property (nonatomic, retain, readonly) NSString *predictedHighTemperatureFahrenheit;
@property (nonatomic, retain, readonly) NSString *predictedHighTemperatureCelsius;
@property (nonatomic, retain, readonly) NSString *predictedHighTemperatureLocale;

//
// predicted low temperatures
//
@property (nonatomic, retain, readonly) NSString *predictedLowTemperatureFahrenheit;
@property (nonatomic, retain, readonly) NSString *predictedLowTemperatureCelsius;
@property (nonatomic, retain, readonly) NSString *predictedLowTemperatureLocale;

//
// current feels like temperatures
//
@property (nonatomic, retain, readonly) NSString *currentFeelsLikeTemperatureFahrenheit;
@property (nonatomic, retain, readonly) NSString *currentFeelsLikeTemperatureCelsius;
@property (nonatomic, retain, readonly) NSString *currentFeelsLikeTemperatureLocale;

@property (nonatomic, assign, readonly) BOOL isLocalWeather;

//
// initialization
// returns an instance of CSWeatherStore
// BOOL local - YES: if location services are enabled returns data for current location
// BOOL local - YES: if location services are disabled returns local weather city
// BOOL local - NO: returns the first city selected in the weather app
//
- (instancetype)initForLocalWeather:(BOOL)local;

// same as initForLocalWeather:(BOOL)local with a update block
// to run a block of code when a weather update is complete.
// the CSWeatherStore instance will be passed as a parameter to the handler.
- (instancetype)initForLocalWeather:(BOOL)local updateHandler:(CSWUpdateHandler)handler;

// same as initForLocalWeather:(BOOL)local updateHandler:(CSWUpdateHandler)handler with auto update
// updates the instance data every autoUpdateInterval(minutes) and triggers the updateHandler on condition
- (instancetype)initForLocalWeather:(BOOL)local autoUpdateInterval:(NSInteger)interval updateHandler:(CSWUpdateHandler)handler;

//
// key value
//
- (id)objectForKey:(NSString *)key;

//
// conveinience type method for initForLocalWeather:(BOOL)local
//
+ (CSWeatherStore *)weatherStoreForLocalWeather:(BOOL)local;

//
// conveinience type method for initForLocalWeather:(BOOL)local updateHandler:(CSWUpdateHandler)handler
//
+ (CSWeatherStore *)weatherStoreForLocalWeather:(BOOL)local updateHandler:(CSWUpdateHandler)handler;

//
// conveinience type method for initForLocalWeather:(BOOL)local autoUpdateInterval:(NSInteger)interval updateHandler:(CSWUpdateHandler)handler
//
+ (CSWeatherStore *)weatherStoreForLocalWeather:(BOOL)local autoUpdateInterval:(NSInteger)interval updateHandler:(CSWUpdateHandler)handler;

@end