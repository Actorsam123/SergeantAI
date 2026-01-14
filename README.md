# SergeantAI

**Don't want to read? Watch this short demo video!**
[https://github.com/Actorsam123/SergeantAI/blob/main/sergeant-ai-first-demo.mp4](https://github.com/user-attachments/assets/a79f0170-3d34-4f11-a6de-af436ecf844e)

🚧 **Status:** Active development (functional prototype)

**SergeantAI** is an iOS accountability assistant focused on habit reinforcement, efficient scheduling, and structured, drill-sergeant-style feedback. The app is designed to move beyond passive reminders by enforcing consequences.

---

## Overview

SergeantAI explores the concept of a **self-directed accountability system** on iOS.  
Users create schedules for tasks, and failure to complete a task by the specified deadline results in an enforced punishment. Completion of the punishment clears the penalty from the system.

This project is currently a prototype and prioritizes **core functionality and system behavior** over UI polish.

---

## Main Workflow

1. The user creates a scheduled task with a specific date and time.
2. If the task is not completed by the deadline, SergeantAI assigns a punishment.
3. Assigned punishments appear on the main dashboard.
4. The user completes the punishment to restore compliance.
5. Once the punishment is verified, it is removed from the dashboard.
6. SergeantAI is notified whenever a scheduled item is added, modified, or deleted.

---

## Current Features

- Task scheduling with deadlines
- Local notifications for task changes and missed deadlines
- Structured accountability feedback
- Punishment tracking via dashboard
- Push-up punishment with basic form enforcement
- Automatic punishment clearance upon completion

---

## Exercise Verification

- Push-ups are verified using **YOLO11-based computer vision**
- Repetitions are counted in-app
- Successful verification automatically resolves the punishment

*Exercise verification is currently limited to push-ups and serves as a proof of concept.*

### Verification Constraints

Push-up repetitions are currently **reliably verified only from a side-view camera angle**.  
This constraint improves detection accuracy and helps prevent common cheating behaviors, including:
- Knees contacting the ground
- Incomplete range of motion
- Excessive back sag/lift or poor form

---

## Tech Stack

- **Platform:** iOS  
- **Language:** Swift  
- **Frameworks:** SwiftUI  
- **Computer Vision:** YOLO11  
- **Tools:** Xcode  

---

## Known Issues and Limitations

- Rep tracking may be unreliable when more than one person is present in the camera frame.

---

## Planned Improvements

- Support for additional punishment types
- Improved UI/UX
- More robust exercise verification
- Expanded customization options
- Codebase cleanup and refactoring

---

## Notes

This project is under active development.  
Design decisions, structure, and features may change as the system evolves.
