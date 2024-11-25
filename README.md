# Geocast - Weather Forecasting by Address

## Assignment Requirements
### Coding Assignment
#### Requirements:
* [DONE] Must be done in Ruby on Rails
* [DONE] Accept an address as input
* [DONE] Retrieve forecast data for the given address. This should include, at minimum, the current temperature (Bonus points - [DONE] Retrieve high/low and/or [DONE] extended forecast)
* [DONE] Display the requested forecast details to the user
* [DONE] Cache the forecast details for 30 minutes for all subsequent requests by zip codes.
* [DONE] Display indicator if result is pulled from cache.

#### Assumptions:
* This project is open to interpretation
* Functionality is a priority over form
* If you get stuck, complete as much as you can

#### Submission:
* Use a public source code repository (GitHub, etc) to store your code
* Send us the link to your completed code

## App Documentation

### Overview 
This app is an interview assignment focused on building a production-ready code with enterprise-level software development practices. Geocast allows users to enter an address and receive the current weather forecast for that location, including temperature, high/low forecasts, and an extended forecast. It also uses caching to improve performance for repeated requests.

### Features
- **Input Address**: Users can input an address to receive weather details.
- **Weather Data Retrieval**: Fetches current temperature, high/low, and extended weather forecasts from the National Weather Service (api.weather.gov).
- **Caching**: Caches weather forecast data for 30 minutes based on zip code to reduce redundant API calls.
- **Cache Indicator**: Shows if the displayed forecast is fetched from the live API or from the cache.

### Source Code
The source code for this application is available on [GitHub](https://github.com/treglu/geocast).

### Installation

This application is currently designed to use Docker Compose for deployment for simplicity. No other prerequisites are required.

#### Prerequisites
- Docker

#### Steps to Install and Run the Application

1. **Clone the repository**
   ```bash
   git clone https://github.com/treglu/geocast.git
   ```

2. **Launch the app**
   ```bash
   docker compose up --build
   ```

3. **Access the application** by going to [http://localhost](http://localhost)

### Development
The best way to work on updating this code is to deploy it in the Docker Dev container.

1. **Clone the repository**
   ```bash
   git clone https://github.com/treglu/geocast.git
   ```

2. **Deploy the development container**
   ```bash
   docker compose -f '/home/andrey/geocast/docker-compose-dev.yml' up -d --build
   ```

3. **Attach VSCode to the running container**
   - Open Visual Studio Code and use the Remote Containers extension to connect to the running Docker container.

4. **Enable caching in the Rails Development Environment**. This functionality is not enabled by default for the development environment.
   ```bash
   bin/rails dev:cache
   ```

### API Services Used
This application uses the following external services:
- **Geolocation Service**: To convert a provided address into geographic coordinates (latitude and longitude).  It fetches data from OpenMaps.com
- **WeatherGovService**: Fetches weather data from the [NOAA Weather API](https://www.weather.gov/documentation/services-web-api). This API provides detailed forecast data, which includes current weather, high/low temperatures, and extended forecast information.

### Testing
The application includes tests to verify functionality, ensuring that:
- Addresses are processed correctly.
- Weather data is fetched from the API as expected.
- Caching works effectively to minimize API calls.

#### Running Tests
To run tests for the application, execute the following command inside the Docker container:
```bash
bundle exec rspec
```
This will run all the RSpec tests to validate the behavior of the application.

### Deployment
This application can be deployed using Docker Compose for easy setup in different environments, including production. Additional deployment scripts can be configured for cloud-based platforms if needed in the future.

### Troubleshooting
- **Invalid Address**: If the entered address cannot be processed, an error message will be displayed. Ensure the address is correctly formatted.
- **Weather Data Not Available**: If the weather data cannot be fetched, the application will display an error. This could be due to network issues or unavailability of the NOAA Weather API.

### Future Improvements
- **User Interface Enhancements**: The current version prioritizes functionality over form. Improving the UI to enhance user experience would be beneficial.
- **Error Handling**: More detailed error messages to help users understand why a request may have failed (e.g., rate-limiting by the weather API).
- **Location Autocomplete**: Implement an address autocomplete feature to make it easier for users to input valid addresses.
- **Additional Weather Metrics**: Include more weather metrics, such as wind speed, humidity, and UV index, for a more comprehensive forecast.
