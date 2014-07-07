//
//  DetailViewController.m
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-04.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "RepoViewController.h"
#import "CoreDataManager.h"
#import "CoreDataFetcher.h"

@interface RepoViewController () <CoreDataFetcherDelegate>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) CoreDataFetcher* fetcher;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation RepoViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupFetcher];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fetcher.paused = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.fetcher.paused = YES;
}

#pragma mark - set up

- (void)setupFetcher
{
    self.fetcher = [[CoreDataFetcher alloc] initWithTableView:self.tableView];
    self.fetcher.fetchedResultsController = self.fetchedResultsController;
    self.fetcher.delegate = self;
    self.fetcher.reuseIdentifier = @"Cell";
}

#pragma mark - GitHub repo

- (void)setDetailObject:(NSManagedObject *)detailObject {
    _detailObject = detailObject;
    [self refreshRepoForUser:detailObject];
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)refreshRepoForUser:(NSManagedObject *)user
{
    static NSString * gitHubReposForUser = @"https://api.github.com/users/%@/repos";
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:gitHubReposForUser, [user valueForKey:@"userName"]]] completionHandler:^(NSData *data,
                                                                                                                                                       NSURLResponse *response,
                                                                                                                                                       NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            NSString *newReposEtag = [httpResponse.allHeaderFields objectForKey:@"ETag"];
            NSString *oldReposEtag = [user valueForKey:@"reposEtag"];
            if ([newReposEtag isEqualToString:oldReposEtag])
                return;
            
            NSError *jsonError;
            NSArray *repos = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:&jsonError];
            if (!jsonError) {
                NSManagedObjectContext *tempContext = [CoreDataManager tempContext];
                [tempContext performBlock:^{
                    NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
                    NSEntityDescription *userEntity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:tempContext];
                    userRequest.entity = userEntity;
                    userRequest.predicate = [NSPredicate predicateWithFormat:@"userName == %@", [user valueForKey:@"userName"]];
                    userRequest.fetchLimit = 1;
                    NSManagedObject *userInContext = [[tempContext executeFetchRequest:userRequest error:nil] objectAtIndex:0];

                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Repo" inManagedObjectContext:tempContext];
                    request.entity = entity;
                    request.predicate = [NSPredicate predicateWithFormat:@"user == %@", userInContext];
                    NSArray *oldRepos = [tempContext executeFetchRequest:request error:nil];
                    for (NSManagedObject *oldRepo in oldRepos) {
                        [tempContext deleteObject:oldRepo];
                        [CoreDataManager saveTempContext:tempContext];
                    }

                    for (NSDictionary *repo in repos) {
                        NSManagedObject *repoObject = [NSEntityDescription insertNewObjectForEntityForName:@"Repo" inManagedObjectContext:tempContext];
                        [repoObject setValue:userInContext forKey:@"user"];
                        [repoObject setValue:[repo valueForKey:@"id"] forKey:@"repoId"];
                        [repoObject setValue:[repo valueForKey:@"name"] forKey:@"repoName"];
                        [repoObject setValue:[repo valueForKey:@"description"] forKey:@"repoDescription"];
                        [repoObject setValue:[repo valueForKey:@"forks_count"] forKey:@"forkCount"];
                        [repoObject setValue:[repo valueForKey:@"stargazers_count"] forKey:@"starCount"];
                        [repoObject setValue:[repo valueForKey:@"watchers_count"] forKey:@"watcherCount"];
                        [repoObject setValue:[repo valueForKey:@"clone_url"] forKey:@"cloneUrl"];
                        [repoObject setValue:[repo valueForKey:@"updated_at"] forKey:@"updateDate"];
                        [repoObject setValue:[repo valueForKey:@"created_at"] forKey:@"createDate"];
                        
                        [CoreDataManager saveTempContext:tempContext];
                    };
                    
                    [userInContext setValue:newReposEtag forKey:@"reposEtag"];
                    [CoreDataManager saveTempContext:tempContext];
                }];
            }
        } else {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Server responded with %d", httpResponse.statusCode]
                                                             message:[[NSJSONSerialization JSONObjectWithData:data
                                                                                                      options:NSJSONReadingAllowFragments
                                                                                                        error:nil] description]
                                                            delegate:self
                                                   cancelButtonTitle:@"Continue"
                                                   otherButtonTitles:nil];
            [alert show];
        }
    }] resume];
}

#pragma mark - fetcher delegate

- (void)configureCell:(UITableViewCell *)cell withObject:(id)object
{
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [object valueForKey:@"repoName"], [object valueForKey:@"repoDescription"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ stars, %@ watchers, %@ forks, last updated at %@", [object valueForKey:@"starCount"], [object valueForKey:@"watcherCount"], [object valueForKey:@"forkCount"], [object valueForKey:@"updateDate"]];
}

- (void)deleteObject:(NSManagedObject *)object
{
    NSString* actionName = [NSString stringWithFormat:NSLocalizedString(@"Delete \"%@\"", @"Delete undo action name"), [object valueForKey:@"userName"]];
    [self.undoManager setActionName:actionName];
    [object.managedObjectContext deleteObject:object];
}

#pragma mark - fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *mainContext = [CoreDataManager defaultMainContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Repo" inManagedObjectContext:mainContext];
    request.entity = entity;
    request.predicate = [NSPredicate predicateWithFormat:@"user == %@", self.detailObject];
    request.fetchBatchSize = 20;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"repoName" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    request.sortDescriptors = sortDescriptors;
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:mainContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController = controller;
    
    return _fetchedResultsController;
}

#pragma mark - split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
    return YES;
}

@end
