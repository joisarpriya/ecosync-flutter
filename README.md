# EcoSync – Smart Energy and Pollution Monitoring Platform

EcoSync is a sustainability-focused application designed to help users understand, control, and optimize their electricity usage while correlating it with environmental pollution data.

In most households, energy consumption is invisible. Users receive electricity bills without knowing which appliances are responsible for high usage or how their consumption contributes to environmental pollution. EcoSync addresses this gap by combining real-time energy monitoring, air quality visualization, and AI-driven insights into a single, usable platform.

The goal is not just to show data, but to help users make better decisions.

---

## Problem Statement

Modern energy consumption faces three major issues:

1. Lack of visibility
   Users do not know how much power individual appliances consume or how usage patterns affect monthly bills.

2. Disconnection between energy and pollution
   Energy usage directly contributes to pollution, but existing applications treat these domains separately, limiting awareness and accountability.

3. Actionless data
   Even when data is available, it is rarely presented in a way that helps users take practical, immediate action.

Because of these gaps, electricity is wasted, costs rise, and environmental impact continues unnoticed.

---

## Proposed Solution

EcoSync provides a unified platform that:

* Tracks energy usage at the appliance level
* Estimates electricity bills in real time
* Visualizes air quality data on an interactive map
* Uses AI to analyze patterns and suggest optimizations
* Allows control of smart devices through cloud and Bluetooth connectivity

By combining these capabilities, EcoSync turns raw data into actionable insight.

---

## Features

### User Authentication

* Secure login and registration using Firebase Authentication
* User-specific data isolation and persistence

### Energy Monitoring and Bill Estimation

* Appliance-wise energy tracking
* Daily, weekly, and monthly consumption trends
* Real-time electricity bill estimation
* Clear identification of high-consumption devices

### Smart Device Control

* Firebase-based device state control
* Architecture support for ESP32 and relay modules
* Bluetooth device discovery and pairing
* Remote ON/OFF control of connected appliances

### Air Quality Monitoring

* Google Maps integration for pollution visualization
* Color-coded AQI representation based on severity
* Location-based pollution awareness
* Correlation between energy usage and environmental conditions

### AI-Based Energy Optimization

* Gemini AI integration for pattern analysis
* Usage-based recommendations
* Energy-saving suggestions based on behavior and environment
* Focus on reducing both cost and pollution impact

### Data Visualization

* Accurate and safe graphs
* Proper axis labels for energy and AQI
* Legends clearly explaining each data line
* Stable handling of missing or partial data

### Reports and Insights

* Structured summaries for user understanding
* PDF report generation for historical data
* Insight-driven recommendations rather than raw statistics

### UI and UX

* Fully functional screens with no placeholders
* Interactive navigation and responsive layouts
* Clean, production-style interface
* Designed for real-world usability rather than demo appearance

---

## Technologies Used

### Core Technologies

* Flutter (Web and Application)
* Firebase Authentication
* Cloud Firestore
* Firebase Hosting

### Google Technologies

* Flutter
* Firebase (Auth, Firestore, Hosting)
* Google Maps Platform
* Gemini AI
* Google Cloud Infrastructure

### Hardware Integration (Supported)

* ESP32 microcontroller
* Relay modules
* Bluetooth-enabled smart switches

The current MVP demonstrates functionality using Firebase-backed data while maintaining full compatibility with real hardware integration.

---

## Live Deployment

Live MVP URL
[https://ecosync-bcc6a.web.app](https://ecosync-bcc6a.web.app)

GitHub Repository
[https://github.com/joisarpriya/ecosync-flutter](https://github.com/joisarpriya/ecosync-flutter)

---

## Uniqueness of the Solution

Unlike existing solutions that focus only on energy monitoring or only on pollution data, EcoSync combines both domains into a single system.

The application does not stop at monitoring. It enables control, provides insights, and guides users toward better decisions using AI. This makes EcoSync a decision-support platform rather than a passive dashboard.

---

## Future Enhancements

* Integration with real-time government AQI APIs
* Predictive pollution forecasting
* Advanced smart-home automation rules
* Carbon footprint scoring per household
* City-level dashboards for large-scale monitoring

---

## Project Status

* Fully functional MVP
* Deployed and live
* Uses required Google technologies
* Scalable architecture
* Designed for real-world usage scenarios

---

## Developer

Priya Joisar
B.Tech
Flutter and Firebase Developer
AI and Sustainability Focus

---

EcoSync is built on the idea that meaningful change happens when users clearly understand the impact of their actions and are given the tools to act on that understanding.

---



