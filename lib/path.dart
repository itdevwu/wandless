import 'package:sensors_plus/sensors_plus.dart';

class PointAccInfo {
  DateTime time;
  List<double> acceleration = [0.0, 0.0, 0.0];

  void setAcceleration(List<double> acceleration) {
    if (acceleration.isEmpty == true || acceleration.length != 3) {
      throw StateError("Not a 3d vector!");
    }

    this.acceleration = acceleration;
  }

  PointAccInfo(this.time, UserAccelerometerEvent accEvent);
}

int binarySearch(List<double> list, double value) {
  int l = 0, r = list.length - 1;
  int mid = (l + r) >> 1;

  while (mid + 1 < r) {
    mid = (l + r) >> 1;
    if (list[mid] < value) {
      l = mid + 1;
    } else if (list[mid] > value) {
      r = mid - 1;
    } else {
      return mid;
    }
  }

  return mid;
}

double interpolation(double first, double second, double ratio) {
  if (ratio < 0.0 || ratio > 1.0) {
    throw StateError("Ratio of interpolation must between 0 and 1!");
  }

  return first + (second - first) * ratio;
}

class RouteSeries {
  late List<PointAccInfo> motionPoints;
  int samplingRate = 100; // Unit: Hz
  int timeout = 2; // Unit: s

  void setSamplingRate(int samplingRate) {
    this.samplingRate = samplingRate;
  }

  void setTimeout(int timeout) {
    this.timeout = timeout;
  }

  List<List<double>> toAccelerationTensor() {
    var curMotionPoints = motionPoints;
    List<List<double>> tensor = [];

    int totPoints = timeout * samplingRate;
    double avgDeltaTime = timeout * 1000.0 / totPoints; // Unit: ms

    List<double> relativeTimes = [0.0, 0.0];
    for (int i = 2; i <= totPoints; ++i) {
      relativeTimes.add(curMotionPoints[-(i - 1)]
          .time
          .difference(curMotionPoints[-i].time)
          .inMilliseconds as double);
    }

    for (int i = 1; i <= totPoints; ++i) {
      var index = binarySearch(relativeTimes, (i - 1) * avgDeltaTime);
      tensor.add([
        interpolation(
            curMotionPoints[-(i + 1)].acceleration[0],
            curMotionPoints[-i].acceleration[0],
            ((i - 1) * avgDeltaTime - relativeTimes[index]) / avgDeltaTime),
        interpolation(
            curMotionPoints[-(i + 1)].acceleration[1],
            curMotionPoints[-i].acceleration[1],
            ((i - 1) * avgDeltaTime - relativeTimes[index]) / avgDeltaTime),
        interpolation(
            curMotionPoints[-(i + 1)].acceleration[2],
            curMotionPoints[-i].acceleration[2],
            ((i - 1) * avgDeltaTime - relativeTimes[index]) / avgDeltaTime),
      ]);
    }

    return tensor;
  }

  List<List<double>> toVelocityTensor(List<double> initVelocity) {
    if (initVelocity.length != 3) {
      throw StateError("Velocity vector must be 3D!");
    }

    var totPoints = timeout * samplingRate;
    double avgDeltaTime = timeout * 1000.0 / totPoints; // Unit: ms

    var accTensor = toAccelerationTensor();

    List<List<double>> tensor = [initVelocity];
    for (int i = 1; i < totPoints; ++i) {
      tensor.add([
        tensor[i - 1][0] + (avgDeltaTime * accTensor[i - 1][0]),
        tensor[i - 1][1] + (avgDeltaTime * accTensor[i - 1][1]),
        tensor[i - 1][2] + (avgDeltaTime * accTensor[i - 1][2]),
      ]);
    }

    return tensor;
  }

  List<List<double>> toPositionTensor(
      List<double> initVelocity, List<double> initPosition) {
    if (initPosition.length != 3 || initVelocity.length != 3) {
      throw StateError("Position & velocity vector must be 3D!");
    }

    var totPoints = timeout * samplingRate;
    double avgDeltaTime = timeout * 1000.0 / totPoints; // Unit: ms

    var velTensor = toVelocityTensor(initVelocity);

    List<List<double>> tensor = [initPosition];
    for (int i = 1; i < totPoints; ++i) {
      tensor.add([
        tensor[i - 1][0] + (avgDeltaTime * velTensor[i - 1][0]),
        tensor[i - 1][1] + (avgDeltaTime * velTensor[i - 1][1]),
        tensor[i - 1][2] + (avgDeltaTime * velTensor[i - 1][2]),
      ]);
    }

    return tensor;
  }
}
