angular.module('app', [])
    .controller('TwilioCtrl', [
        '$scope', '$http',
        function($scope,$http){
            $scope.abc = function (phone_number) {
                $http({
                    method: 'GET',

                    url: '/twilio/get_messages',

                    params: { phone_number: phone_number },
                    responseType:'json'


                }).
                    success(function(data, status, headers, config) {
                        console.log(data);
                        applyRemoteData(data);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("error");
                    });

            }

            function applyRemoteData(messages) {
                $scope.messages = messages;
            }
        }


    ]);