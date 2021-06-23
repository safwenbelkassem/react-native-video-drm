## react-native-video-DRM

a react native video DRM player that is fully compatable with Azure Media Services for both widevine and fairplay.

## Main Patches : 

**** Playback with DRM  ****

- Adding support for offline playback in both IOS and Android for Fairplay DRM and Widevine DRM.
- Playback with the persisted assets , if none of these exist , we will fetch the key for the stream and use them to playback our content. 


**** Download with DRM  ****

- Key and asset Persistance with a unique id for the key in case you need a key for each user and the playback happens automatically for each key and it's according asset.

**** Updates above the already existing React-native-VIDEO  ****


- Implement the key persistence / License persistence logic in both ios and android.
- Adding cancel on download / multiple downloads in exoplayer.
