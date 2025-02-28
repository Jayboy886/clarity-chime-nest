# ChimeNest
A decentralized sleep tracking and white noise generator app with customizable smart alarms built on Stacks blockchain.

## Features
- Track sleep sessions with start/end times and quality metrics
- Store white noise sound preferences and playlists 
- Set and manage smart alarms with custom rules
- View sleep analytics and history
- Reward system for consistent sleep habits

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Start a sleep session
(contract-call? .chime-nest start-sleep)

;; End sleep session with quality rating
(contract-call? .chime-nest end-sleep u8)

;; Set white noise preferences
(contract-call? .chime-nest set-sound-preference "rain" u70)

;; Set smart alarm
(contract-call? .chime-nest set-alarm u7 u30 "gradual")
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
