# coding: utf-8
class AsciicastSnapshotUpdater

  def update(asciicast, at_seconds = nil)
    Sidekiq::Client.push(
      'queue' => 'rails',
      'class' => 'Asciinema.Asciicasts.SnapshotUpdater.Exq',
      'args' => [asciicast.id]
    )

    sleep 3 # wait for bg job to complete ¯\_(ツ)_/¯
  end
end
