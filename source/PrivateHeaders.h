//
// Created by Dana Buehre on 9/28/17.
// Copyright (c) 2018 CreatureCoding. All rights reserved.
//

@interface WFTypes : NSObject
+ (NSArray *)WeatherDescriptions;
@end

@interface CLLocationManager : NSObject
@property (nonatomic, readonly) BOOL locationServicesEnabled;
+ (id)sharedManager;
@end

@interface CLLocation : NSObject
@end

@protocol CLLocationManagerDelegate <NSObject>
@optional
- (void)locationManager:(CLLocationManager *)locationManager didUpdateToLocation:(CLLocation *)toLocation fromLocation:(CLLocation *)fromLocation;
- (void)locationManager:(CLLocationManager *)locationManager didChangeAuthorizationStatus:(id)status;

@end

@interface WFTemperature : NSObject
@property (nonatomic) double celsius;
@property (nonatomic) double fahrenheit;
@end

@interface City : NSObject
@property (nonatomic, retain) WFTemperature *temperature;
@property(nonatomic) NSInteger conditionCode;
@property (nonatomic, copy) CLLocation *location;
@property (nonatomic, copy) NSArray *dayForecasts;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) WFTemperature *feelsLike;
- (NSString *)naturalLanguageDescription;
- (NSString *)naturalLanguageDescriptionWithDescribedCondition:(out NSInteger *)condition;
- (NSDate *)updateTime;
- (NSString *)displayName;
- (WFTemperature *)temperature;
- (NSString *)detailedDescription;
@end

@interface WeatherPreferences : NSObject
@property (assign, setter = setLocalWeatherEnabled :, getter = isLocalWeatherEnabled, nonatomic) BOOL isLocalWeatherEnabled;
@property (nonatomic, readonly) City *localWeatherCity;
+ (WeatherPreferences *)sharedPreferences;
- (NSArray<City *> *)loadSavedCities;
- (NSArray<City *> *)_defaultCities;
- (BOOL)isCelsius;
@end

@interface WeatherLocationManager : NSObject
+ (WeatherLocationManager *)sharedWeatherLocationManager;
- (WeatherLocationManager *)initWithPreferences:(WeatherPreferences *)preferences effectiveBundleIdentifier:(NSString *)bundleIdentifier;
- (CLLocation *)location;
@end

@interface WAForecastModel : NSObject
@property (nonatomic, retain) City *city;
- (City *)city;
@end

@interface WATodayModel : NSObject
+ (id)autoupdatingLocationModelWithPreferences:(id)preferences effectiveBundleIdentifier:(id)bundle;
@end

@interface WATodayAutoupdatingLocationModel : WATodayModel
@property (nonatomic, retain) WeatherLocationManager *locationManager;
+ (id)alloc;
- (void)_executeLocationUpdateForLocalWeatherCityWithCompletion:(id)completion;
- (void)_executeLocationUpdateForFirstWeatherCityWithCompletion:(id)completion;
- (WATodayAutoupdatingLocationModel *)initWithPreferences:(id)preferences effectiveBundleIdentifier:(id)bundle;
- (WATodayAutoupdatingLocationModel *)init;
- (WAForecastModel *)forecastModel;
- (void)setPreferences:(id)arg1;
- (BOOL)isLocationTrackingEnabled;
- (BOOL)locationServicesActive;
@end

@interface TWCCityUpdater : NSObject
+ (id)sharedCityUpdater;
- (void)updateWeatherForCities:(NSArray *)cities withCompletionHandler:(id)handler;
@end

@interface TWCLocationUpdater : TWCCityUpdater
@property (nonatomic, retain) City *currentCity;
+ (TWCLocationUpdater *)sharedLocationUpdater;
- (void)updateWeatherForLocation:(id)arg1 city:(id)arg2 withCompletionHandler:(id)arg3;
- (void)updateWeatherForLocation:(id)location city:(id)city isFromFrameworkClient:(BOOL)fromClient withCompletionHandler:(id)completion;
@end

@interface WADayForecast : NSObject
@property (nonatomic, copy) WFTemperature *high;                    //@synthesize high=_high - In the implementation block
@property (nonatomic, copy) WFTemperature *low;
@end

@interface WeatherImageLoader : NSObject
+ (id)sharedImageLoader;
+ (id)conditionImageBundle;
+ (id)conditionImageNamed:(NSString *)name;
+ (id)conditionImageWithConditionIndex:(NSInteger)conditionCode;
+ (id)conditionImageNameWithConditionIndex:(NSInteger)conditionCode;
@end
