# JMonkeyEngine Bullet builder
Automatic build of [JMonkeyEngine bullet bindings](https://github.com/jMonkeyEngine/jmonkeyengine) with travis.

##Access to the latest builds
###Gradle
<big><pre>
repositories { 
  maven { 
    url "http://dl.bintray.com/riccardo/jme3-bullet-native" 
  } 
}
dependencies {
  compile "org.jmonkeyengine.bullet_builder:jme3-bullet-native:[<i>$VERSION</i>](https://github.com/riccardobl/jme3-bullet-builder/releases)"
}
</pre></big>

`$VERSION` has to be replaced with a tag chosen in the [release page](https://github.com/riccardobl/jme3-bullet-builder/releases)


###Bintray repo
https://bintray.com/riccardo/jme3-bullet-native/jme3-bullet-native

