;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-rating (err u101))
(define-constant err-no-active-session (err u102))
(define-constant err-session-exists (err u103))
(define-constant err-invalid-volume (err u104))

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
        (ok true)
      )
    )
  )
)

(define-public (end-sleep (rating uint))
  (let ((current-session (default-to 
    {start-time: u0, end-time: u0, quality: u0, active: false}
    (map-get? sleep-sessions tx-sender))))
    (if (and (>= rating u0) (<= rating u10))
      (if (get active current-session)
        (begin
          (map-set sleep-sessions tx-sender
            {
              start-time: (get start-time current-session),
              end-time: block-height,
              quality: rating,
              active: false
            }
          )
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
      (ok true)
    )
    err-invalid-volume
  )
)

(define-public (set-alarm (hour uint) (minute uint) (alarm-type (string-ascii 20)))
  (begin
    (map-set alarms tx-sender
      {
        hour: hour,
        minute: minute,
        type: alarm-type
      }
    )
    (ok true)
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
