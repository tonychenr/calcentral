(function(calcentral) {
  'use strict';

  /**
   * Academics controller
   */
  calcentral.controller('AcademicsController', ['apiService', '$http', '$scope', function(apiService, $http, $scope) {

    apiService.util.setTitle('My Academics');

    $scope.getUserStatus = function() {
      // return $http.get('/dummy/json/status_oski_sample.json').success(function(data) {
      return $http.get('/api/my/status').success(function(data) {
        $scope.user_status = data;
      });
    };
    $scope.getUserStatus();

    $scope.getAcademics = function() {
      // return $http.get('/dummy/json/academics.json').success(function(data) {
      return $http.get('/api/my/academics').success(function(data) {
        $scope.academics = data;
        $scope.semesters = data.semesters[0]; // Assuming just one semester for now
      });
    };
    $scope.getAcademics();

    $scope.toggleBlockHistory = function() {
      $scope.show_block_history = !$scope.show_block_history;
      apiService.analytics.trackEvent(['Block history', 'Show history panel - ' + $scope.show_block_history ? 'Show' : 'Hide']);
    };

  }]);

})(window.calcentral);
