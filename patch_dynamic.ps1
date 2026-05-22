$f1 = "lib/services/web_audio_recorder.dart"
$c1 = Get-Content $f1 -Raw
$c1 = $c1 -replace "track\.stop\(\)", "(track as dynamic).stop()"
Set-Content $f1 -Value $c1

$f2 = "lib/widgets/web_audio_player_widget.dart"
$c2 = Get-Content $f2 -Raw
$c2 = $c2 -replace "html\.AudioElement\? _audioElement;", "dynamic _audioElement;"
$c2 = $c2 -replace "html\.AudioElement\(widget\.audioUrl\)", "(html.AudioElement() as dynamic)..src = widget.audioUrl"
$c2 = $c2 -replace "_audioElement\!", "_audioElement"
Set-Content $f2 -Value $c2
