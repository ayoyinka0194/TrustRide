 TrustRide  CrossPlatform Reputation System

A blockchainbased reputation system built on Stacks that creates immutable, portable ratings for ridehailing drivers and riders across multiple platforms.

 Overview

TrustRide solves the reputation portability problem in ridehailing by storing user ratings on the blockchain. Drivers and riders can build their reputation once and use it across any integrated platform, creating a more trustworthy and efficient transportation ecosystem.

 Key Features

 🌟 Immutable Reputation System
 Permanent, tamperproof ratings stored on blockchain
 Crossplatform reputation that follows users everywhere
 Precisionscaled reputation scores (010,000 scale)
 Automatic reputation calculation and updates

 👥 DualRole User Support
 Support for drivers, riders, and users who are both
 Flexible user registration with role specification
 Separate reputation tracking for different roles
 Comprehensive user profile management

 🚗 Trip Verification System
 Secure trip recording with driver/rider verification
 Platform integration for multiple ridehailing services
 Trip completion tracking and verification
 Antifraud mechanisms to prevent fake trips

 Comprehensive Rating System
 15 star rating system with optional comments
 Prevents selfrating and duplicate ratings
 Realtime reputation score updates
 Rating history tracking and verification

 🔒 Security & AntiGaming
 Input validation and sanitization on all functions
 Authorization checks for rating submissions
 Admin controls for platform management
 Comprehensive error handling with descriptive codes

 Smart Contract Functions

 Public Functions
 registeruser()  Register as a driver, rider, or both
 registerplatform()  Add new ridehailing platform integration
 recordtrip()  Log completed trips for rating eligibility
 submitrating()  Submit ratings for completed trips
 verifytrip()  Admin function to verify trip authenticity
 deactivateuser()  Admin function to deactivate problematic users
 updateplatformfee()  Admin function to adjust platform fees

 ReadOnly Functions
 getuserprofile()  Retrieve complete user profile and stats
 getuserreputation()  Get user's current reputation score
 getuseraveragerating()  Calculate user's average star rating
 gettriprecord()  Retrieve trip details and rating status
 getrating()  Get specific rating details between users
 getplatformintegration()  Check platform integration status
 calculatereputationscore()  Calculate reputation from ratings

 Getting Started

 Prerequisites
 Clarinet CLI installed
 Stacks wallet for testing
 Basic understanding of Clarity smart contracts

 Installation
1. Clone the repository
2. Run clarinet check to verify contract syntax
3. Use clarinet console for interactive testing
4. Deploy to testnet for integration testing

 Testing
bash
clarinet check
clarinet test


 Contract Architecture

The TrustRide system uses five main data structures:

 User Profiles: Store user information, reputation scores, and activity status
 Trip Records: Track completed trips and rating completion status
 Ratings: Store individual ratings with comments and verification
 Rating History: Maintain chronological rating records for users
 Platform Integrations: Manage connected ridehailing platforms


 Reputation Calculation

Reputation scores are calculated using a precisionscaled algorithm:

 Base rating: 15 stars
 Precision scale: Multiplied by 2,000 for accuracy
 Maximum score: 10,000 (equivalent to 5.0 stars)
 Automatic updates: Recalculated with each new rating


 Security Features

 Input Validation: All user inputs are validated and sanitized
 Authorization Controls: Users can only rate trips they participated in
 AntiGaming: Prevents selfrating, duplicate ratings, and fake trips
 Admin Oversight: Administrative functions for platform management
 Immutable Records: Ratings cannot be modified or deleted once submitted


 Platform Integration

TrustRide supports integration with multiple ridehailing platforms:

 Platform registration and management
 Trip tracking across different services
 Unified reputation across all platforms
 Analytics and reporting capabilities


 Contributing

This project is part of the Stacks blockchain ecosystem. Contributions should follow Clarity best practices and include comprehensive tests for all new functionality.

 License

MIT License  Built for the Stacks blockchain ecosystem to enhance trust in ridehailing