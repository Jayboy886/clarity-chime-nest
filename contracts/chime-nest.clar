;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-rating (err u101))
(define-constant err-no-active-session (err u102))
(define-constant err-session-exists (err u103))
(define-constant err-invalid-volume (err u104))
(define-constant err-invalid-time (err u105))

;; Events
(define-data-var total-sleep-time uint u0)
(define-data-var sleep-streak uint u0)

(define-map user-stats principal
  {
    total-sessions: uint,
    avg-quality: uint,
    total-sleep-time: uint
  }
)

;; Data structures
(define-map sleep-sessions principal
  {
    start-time: uint,
    end-time: uint,
    quality: uint,
    active: bool
  }
)

(define-map sound-preferences principal
  {
    sound-type: (string-ascii 20),
    volume: uint
  }
)

(define-map alarms principal
  {
    hour: uint,
    minute: uint,
    type: (string-ascii 20)
  }
)

;; Helper functions
(define-private (is-valid-time (hour uint) (minute uint))
  (and
    (< hour u24)
    (< minute u60)
  )
)

(define-private (update-stats (duration uint) (quality uint))
  (let (
    (current-stats (default-to
      {total-sessions: u0, avg-quality: u0, total-sleep-time: u0}
      (map-get? user-stats tx-sender)))
    (new-total-sessions (+ (get total-sessions current-stats) u1))
    (new-total-quality (+ (* (get avg-quality current-stats) 
                           (get total-sessions current-stats)) 
                        quality))
    (new-avg-quality (/ new-total-quality new-total-sessions))
  )
    (map-set user-stats tx-sender
      {
        total-sessions: new-total-sessions,
        avg-quality: new-avg-quality,
        total-sleep-time: (+ (get total-sleep-time current-stats) duration)
      }
    )
  )
)

;; Public functions
(define-public (start-sleep)
  (let ((current-session (default-to 
    {start-time: u0, end-time: u0, quality: u0, active: false}
    (map-get? sleep-sessions tx-sender))))
    (if (get active current-session)
      err-session-exists
      (begin
        (map-set sleep-sessions tx-sender
          {
            start-time: block-height,
            end-time: u0,
            quality: u0,
            active: true
          }
        )
        (print {event: "session-started", user: tx-sender})
        (ok true)
      )
    )
  )
)

(define-public (end-sleep (rating uint))
  (let (
    (current-session (default-to 
      {start-time: u0, end-time: u0, quality: u0, active: false}
      (map-get? sleep-sessions tx-sender)))
    (current-height block-height)
  )
    (if (and (>= rating u0) (<= rating u10))
      (if (get active current-session)
        (begin
          (map-set sleep-sessions tx-sender
            {
              start-time: (get start-time current-session),
              end-time: current-height,
              quality: rating,
              active: false
            }
          )
          (update-stats (- current-height (get start-time current-session)) rating)
          (print {event: "session-ended", user: tx-sender, quality: rating})
          (ok true)
        )
        err-no-active-session
      )
      err-invalid-rating
    )
  )
)

(define-public (set-sound-preference (sound (string-ascii 20)) (volume uint))
  (if (<= volume u100)
    (begin
      (map-set sound-preferences tx-sender
        {
          sound-type: sound,
          volume: volume
        }
      )
      (print {event: "preferences-updated", user: tx-sender})
      (ok true)
    )
    err-invalid-volume
  )
)

(define-public (set-alarm (hour uint) (minute uint) (alarm-type (string-ascii 20)))
  (if (is-valid-time hour minute)
    (begin
      (map-set alarms tx-sender
        {
          hour: hour,
          minute: minute,
          type: alarm-type
        }
      )
      (print {event: "alarm-set", user: tx-sender})
      (ok true)
    )
    err-invalid-time
  )
)

;; Read only functions
(define-read-only (get-session-info)
  (ok (map-get? sleep-sessions tx-sender))
)

(define-read-only (get-sound-preferences)
  (ok (map-get? sound-preferences tx-sender))
)

(define-read-only (get-alarm)
  (ok (map-get? alarms tx-sender))
)

(define-read-only (get-user-stats)
  (ok (map-get? user-stats tx-sender))
)
