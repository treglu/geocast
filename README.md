# Geocast - Weather Forecasting by address

## Assignment Requirements
Coding Assignment
#### Requirements:
* [DONE] Must be done in Ruby on Rails
* [DONE] Accept an address as input
* [DONE] Retrieve forecast data for the given address. This should include, at minimum, the
current temperature (Bonus points - [DONE] Retrieve high/low and/or [DONE] xtended forecast)
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

## App Documenation

### Overview 
This app is an interview assignment focused on building a production-ready code with 
enterprise-level software development practices

### Installation

This application is currently designed to use Docker Compose for deployment for simplicity. 
No other prerequisites are required.


1. Clone the repository
```bash
git clone https://github.com/treglu/geocast.git
```

2. Launch app
```bash
docker compose up
```

3. Access the application by going to http://localhost